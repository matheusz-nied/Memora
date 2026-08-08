import 'dart:typed_data';

import 'pdf_document.dart';
import 'pdf_encodings.dart';
import 'pdf_lexer.dart';
import 'pdf_objects.dart';

/// Uma fonte do PDF, reduzida ao que a extração de texto precisa saber:
/// como quebrar os bytes em códigos, que texto cada código representa e
/// quanto ele avança na linha.
///
/// A ordem de preferência para descobrir o texto é sempre a mesma:
/// `/ToUnicode` primeiro, porque é a única informação que o gerador escreveu
/// *de propósito* para ser lida; depois `/Differences`; e só então a
/// codificação base. Inverter isso quebra fonte com subconjunto embutido, em
/// que o código 1 pode ser qualquer letra.
class PdfFont {
  PdfFont._({
    required this.composite,
    required this.baseFont,
    required List<int> encoding,
    required Map<int, String> differences,
    required Map<int, String> toUnicode,
    required Map<int, double> widths,
    required this.defaultWidth,
    required this.widthScale,
    required List<_Codespace> codespaces,
    required this.metricsKnown,
  }) : _encoding = encoding,
       _differences = differences,
       _toUnicode = toUnicode,
       _widths = widths,
       _codespaces = codespaces;

  /// Fonte composta (`/Type0`): códigos de mais de um byte.
  final bool composite;

  final String baseFont;

  /// `true` quando há largura de verdade — do `/Widths` do arquivo ou da
  /// métrica embutida de uma fonte base.
  ///
  /// Quando é `false`, quem interpreta o conteúdo não deve inferir espaço a
  /// partir de posição: sem largura, a posição prevista do próximo glifo é
  /// chute, e o chute vira espaço no meio da palavra.
  final bool metricsKnown;

  final List<int> _encoding;
  final Map<int, String> _differences;
  final Map<int, String> _toUnicode;
  final Map<int, double> _widths;
  final List<_Codespace> _codespaces;

  final double defaultWidth;

  /// Fator que leva a largura para unidades de espaço de texto. É 1/1000 em
  /// quase toda fonte, e o `/FontMatrix` numa `/Type3`.
  final double widthScale;

  /// Quebra os bytes de uma string em códigos de glifo.
  List<int> codesOf(Uint8List bytes) {
    if (!composite) return bytes;

    final out = <int>[];
    var i = 0;

    while (i < bytes.length) {
      var taken = 0;

      for (
        var length = 1;
        length <= 4 && i + length <= bytes.length;
        length++
      ) {
        final value = _readBytes(bytes, i, length);
        if (_codespaces.any((range) => range.contains(value, length))) {
          out.add(value);
          taken = length;
          break;
        }
      }

      if (taken == 0) {
        // Sem codespace que sirva. Dois bytes é o que `/Identity-H` usa e o
        // que praticamente toda fonte composta faz na prática.
        taken = i + 2 <= bytes.length ? 2 : 1;
        out.add(_readBytes(bytes, i, taken));
      }

      i += taken;
    }

    return out;
  }

  static int _readBytes(Uint8List bytes, int start, int length) {
    var value = 0;
    for (var i = 0; i < length; i++) {
      value = (value << 8) | bytes[start + i];
    }
    return value;
  }

  /// Texto que o código representa. Vazio quando não há como saber.
  String textOf(int code) {
    final mapped = _toUnicode[code];
    if (mapped != null) return mapped;

    final difference = _differences[code];
    if (difference != null) return difference;

    if (composite) return '';

    final rune = code >= 0 && code < _encoding.length ? _encoding[code] : 0;
    return rune > 0 ? String.fromCharCode(rune) : '';
  }

  /// Avanço do glifo, em unidades de espaço de texto (1.0 = o corpo da fonte).
  double widthOf(int code) => (_widths[code] ?? defaultWidth) * widthScale;

  /// `/Tw` só vale para o código 32 de um byte só — é a regra da
  /// especificação, e aplicá-la a fonte composta desalinha texto CJK.
  bool takesWordSpacing(int code) => !composite && code == 32;

  // ------------------------------------------------------------- construção

  /// Monta a fonte a partir do dicionário de recurso.
  static PdfFont load(PdfDocument document, Map<String, Object?> dict) {
    final subtype = document.resolve(dict['Subtype']);
    final baseFont = document.resolve(dict['BaseFont']);
    final name = baseFont is String ? baseFont : '';

    final toUnicode = _readToUnicode(document, dict['ToUnicode']);

    return subtype == 'Type0'
        ? _loadComposite(document, dict, name, toUnicode)
        : _loadSimple(document, dict, name, toUnicode, subtype == 'Type3');
  }

  static PdfFont _loadSimple(
    PdfDocument document,
    Map<String, Object?> dict,
    String baseFont,
    Map<int, String> toUnicode,
    bool isType3,
  ) {
    // `/Encoding` é nome puro ou dicionário com base e diferenças.
    final encodingObject = document.resolve(dict['Encoding']);
    String? baseName;
    final differences = <int, String>{};

    if (encodingObject is String) {
      baseName = encodingObject;
    } else if (encodingObject is Map<String, Object?>) {
      final base = document.resolve(encodingObject['BaseEncoding']);
      if (base is String) baseName = base;

      final list = document.resolve(encodingObject['Differences']);
      if (list is List) {
        // O array alterna código e sequência de nomes: `[32 /space /A 65 /X]`.
        var code = 0;
        for (final item in list) {
          final value = document.resolve(item);
          if (value is num) {
            code = value.toInt();
          } else if (value is String) {
            final text = glyphToText(value);
            if (text.isNotEmpty) differences[code] = text;
            code++;
          }
        }
      }
    }

    final widths = <int, double>{};
    final first = document.resolve(dict['FirstChar']);
    final list = document.resolve(dict['Widths']);

    if (list is List && first is num) {
      final start = first.toInt();
      for (var i = 0; i < list.length; i++) {
        final value = document.resolve(list[i]);
        if (value is num) widths[start + i] = value.toDouble();
      }
    }

    // Sem `/Widths`: ou é uma das 14 fontes base, cuja métrica o leitor deve
    // conhecer, ou não dá para saber.
    var metricsKnown = widths.isNotEmpty;
    if (!metricsKnown) {
      for (var code = 0x20; code <= 0x7E; code++) {
        final width = standardWidth(baseFont, code);
        if (width != null) widths[code] = width;
      }
      metricsKnown = widths.isNotEmpty;
    }

    final descriptor = document.dictOf(dict['FontDescriptor']);
    final missing = document.resolve(descriptor?['MissingWidth']);

    // `/FontMatrix` da Type3 põe a largura em espaço de glifo, não em milésimos.
    var scale = 0.001;
    if (isType3) {
      final matrix = document.resolve(dict['FontMatrix']);
      if (matrix is List && matrix.isNotEmpty) {
        final a = document.resolve(matrix[0]);
        if (a is num && a != 0) scale = a.toDouble();
      }
    }

    return PdfFont._(
      composite: false,
      baseFont: baseFont,
      encoding: buildEncoding(baseName),
      differences: differences,
      toUnicode: toUnicode,
      widths: widths,
      defaultWidth: missing is num ? missing.toDouble() : 0,
      widthScale: scale,
      codespaces: const [],
      metricsKnown: metricsKnown,
    );
  }

  static PdfFont _loadComposite(
    PdfDocument document,
    Map<String, Object?> dict,
    String baseFont,
    Map<int, String> toUnicode,
  ) {
    final descendants = document.resolve(dict['DescendantFonts']);
    final descendant = descendants is List && descendants.isNotEmpty
        ? document.dictOf(descendants.first)
        : null;

    final widths = <int, double>{};
    final defaultWidth = document.resolve(descendant?['DW']);
    _readCidWidths(document, descendant?['W'], widths);

    // `/Encoding` pode ser um CMap embutido; dele só interessam as faixas de
    // codespace, que dizem quantos bytes tem cada código. O mapeamento
    // código→CID não altera o texto quando `/ToUnicode` existe, e ele existe
    // em toda fonte composta que carrega texto de verdade.
    final codespaces = <_Codespace>[];
    final encoding = document.resolve(dict['Encoding']);
    if (encoding is PdfStream) {
      final bytes = document.streamBytes(encoding);
      if (bytes != null) codespaces.addAll(_parseCMap(bytes).codespaces);
    }
    if (codespaces.isEmpty) {
      // `/Identity-H`, `/Identity-V` e os CMaps CJK predefinidos são todos de
      // dois bytes.
      codespaces.add(const _Codespace(0, 0xFFFF, 2));
    }

    return PdfFont._(
      composite: true,
      baseFont: baseFont,
      encoding: const [],
      differences: const {},
      toUnicode: toUnicode,
      widths: widths,
      // 1000 é o padrão da especificação para `/DW`.
      defaultWidth: defaultWidth is num ? defaultWidth.toDouble() : 1000,
      widthScale: 0.001,
      codespaces: codespaces,
      metricsKnown: true,
    );
  }

  /// Lê `/W`, que alterna dois formatos: `c [w1 w2 ...]` para larguras
  /// individuais a partir de `c`, e `cInicio cFim w` para uma faixa inteira.
  static void _readCidWidths(
    PdfDocument document,
    Object? source,
    Map<int, double> into,
  ) {
    final list = document.resolve(source);
    if (list is! List) return;

    var i = 0;
    while (i < list.length) {
      final first = document.resolve(list[i]);
      if (first is! num) break;

      if (i + 1 >= list.length) break;
      final second = document.resolve(list[i + 1]);

      if (second is List) {
        final start = first.toInt();
        for (var j = 0; j < second.length; j++) {
          final width = document.resolve(second[j]);
          if (width is num) into[start + j] = width.toDouble();
        }
        i += 2;
        continue;
      }

      if (second is num && i + 2 < list.length) {
        final width = document.resolve(list[i + 2]);
        final from = first.toInt();
        final to = second.toInt();
        // Faixa absurda é arquivo corrompido: preencher estouraria a memória.
        if (width is num && to >= from && to - from <= 65536) {
          for (var code = from; code <= to; code++) {
            into[code] = width.toDouble();
          }
        }
        i += 3;
        continue;
      }

      break;
    }
  }

  static Map<int, String> _readToUnicode(PdfDocument document, Object? source) {
    final bytes = document.streamBytes(source);
    if (bytes == null) return const {};
    return _parseCMap(bytes).map;
  }

  /// Lê um CMap — o de `/ToUnicode` e o de `/Encoding` usam a mesma sintaxe.
  static _CMap _parseCMap(Uint8List bytes) {
    final result = _CMap();
    final lexer = PdfLexer(bytes);
    final pending = <Object?>[];

    while (true) {
      final token = lexer.parseObject();
      if (token == PdfToken.endOfInput) break;

      if (token is! PdfKeyword) {
        pending.add(token);
        // Os operandos de um bloco cabem numa janela curta; segurar mais só
        // acumula lixo de CMap grande.
        if (pending.length > 8) pending.removeAt(0);
        continue;
      }

      switch (token.value) {
        case 'begincodespacerange':
          _readCodespaces(lexer, result);
        case 'beginbfchar':
          _readBfChars(lexer, result);
        case 'beginbfrange':
          _readBfRanges(lexer, result);
      }
      pending.clear();
    }

    return result;
  }

  static void _readCodespaces(PdfLexer lexer, _CMap into) {
    while (true) {
      final low = lexer.parseObject();
      if (low is! PdfString) return; // `endcodespacerange` ou fim
      final high = lexer.parseObject();
      if (high is! PdfString) return;

      final length = low.bytes.length;
      if (length < 1 || length > 4) continue;
      into.codespaces.add(
        _Codespace(_valueOf(low.bytes), _valueOf(high.bytes), length),
      );
    }
  }

  static void _readBfChars(PdfLexer lexer, _CMap into) {
    while (true) {
      final source = lexer.parseObject();
      if (source is! PdfString) return; // `endbfchar` ou fim
      final target = lexer.parseObject();

      final text = _destinationText(target);
      if (text.isNotEmpty) into.map[_valueOf(source.bytes)] = text;
    }
  }

  static void _readBfRanges(PdfLexer lexer, _CMap into) {
    while (true) {
      final low = lexer.parseObject();
      if (low is! PdfString) return; // `endbfrange` ou fim
      final high = lexer.parseObject();
      if (high is! PdfString) return;
      final target = lexer.parseObject();

      final from = _valueOf(low.bytes);
      final to = _valueOf(high.bytes);
      // Faixa invertida ou gigante só aparece em arquivo quebrado.
      if (to < from || to - from > 65536) continue;

      if (target is List) {
        // Um destino por código: `<20> <22> [<41> <42> <43>]`.
        for (var i = 0; i < target.length && from + i <= to; i++) {
          final text = _destinationText(target[i]);
          if (text.isNotEmpty) into.map[from + i] = text;
        }
        continue;
      }

      if (target is! PdfString) continue;

      // Destino único: incrementa a última unidade a cada código, que é o que
      // a especificação define.
      final units = _utf16Units(target.bytes);
      if (units.isEmpty) continue;

      for (var code = from; code <= to; code++) {
        final shifted = List<int>.of(units);
        shifted[shifted.length - 1] += code - from;
        into.map[code] = String.fromCharCodes(shifted);
      }
    }
  }

  static String _destinationText(Object? target) => switch (target) {
    final PdfString string => String.fromCharCodes(_utf16Units(string.bytes)),
    // Destino como nome de glifo é raro, mas legal na especificação.
    final String name => glyphToText(name),
    _ => '',
  };

  /// Interpreta os bytes de destino como UTF-16BE.
  ///
  /// Descarta `U+0000`: fonte com subconjunto mal gerado mapeia glifo sem
  /// correspondente para zero, e deixar isso passar enche o texto de NUL.
  static List<int> _utf16Units(Uint8List bytes) {
    final units = <int>[];
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final unit = (bytes[i] << 8) | bytes[i + 1];
      if (unit != 0) units.add(unit);
    }
    // Byte solto no fim: destino de um byte só, que alguns geradores emitem.
    if (bytes.length == 1 && bytes[0] != 0) units.add(bytes[0]);
    return units;
  }

  static int _valueOf(Uint8List bytes) {
    var value = 0;
    for (final byte in bytes) {
      value = (value << 8) | byte;
    }
    return value;
  }
}

/// Faixa de códigos de um mesmo número de bytes, vinda de `codespacerange`.
class _Codespace {
  const _Codespace(this.low, this.high, this.length);

  final int low;
  final int high;
  final int length;

  bool contains(int value, int bytes) =>
      bytes == length && value >= low && value <= high;
}

class _CMap {
  final List<_Codespace> codespaces = [];
  final Map<int, String> map = {};
}
