import 'dart:math' as math;
import 'dart:typed_data';

import 'pdf_document.dart';
import 'pdf_fonts.dart';
import 'pdf_lexer.dart';
import 'pdf_objects.dart';

/// Interpretador do content stream: executa os operadores de texto e devolve
/// o que estava escrito na página.
///
/// PDF não guarda texto — guarda instruções de desenho. Um parágrafo pode sair
/// como um `Tj` por linha, um por palavra ou um por glifo, e o espaço entre
/// palavras costuma ser um deslocamento da matriz, não um caractere. Por isso a
/// extração é geométrica: acompanha a posição da caneta e decide onde cabe um
/// espaço e onde começou outra linha.
///
/// A régua é a largura de cada glifo. Quando a fonte não informa largura
/// nenhuma ([PdfFont.metricsKnown] falso), o palpite de posição deixa de valer
/// e só a mudança de linha é considerada — inventar espaço a partir de
/// coordenada chutada parte palavra no meio, que é pior do que juntar duas.
class PdfTextExtractor {
  PdfTextExtractor(this._document);

  final PdfDocument _document;
  final Map<Object, PdfFont> _fonts = {};

  /// Fração do corpo da fonte a partir da qual um vão horizontal vira espaço.
  /// Um espaço tipográfico tem cerca de 0.25 em; o limiar fica abaixo disso
  /// para pegar também as fontes de espaço estreito.
  static const double _spaceRatio = 0.17;

  /// Diferença vertical, em corpos de fonte, que caracteriza outra linha.
  /// Acima de meio corpo não é mais sobrescrito nem acento.
  static const double _lineRatio = 0.5;

  /// Recuo horizontal que denuncia início de linha mesmo sem mudança de altura
  /// — o caso de texto em colunas.
  static const double _carriageRatio = 0.5;

  /// Profundidade máxima de `Do` aninhado. Form XObject que se referencia
  /// existe em arquivo gerado por programa com bug.
  static const int _maxFormDepth = 8;

  String extractPage(PdfPage page) {
    final state = _State(page.resources);
    final buffer = StringBuffer();
    _run(page.content, page.resources, state, buffer, 0);
    return buffer.toString();
  }

  void _run(
    Uint8List content,
    Map<String, Object?> resources,
    _State state,
    StringBuffer out,
    int depth,
  ) {
    final lexer = PdfLexer(content);
    final operands = <Object?>[];

    while (true) {
      final token = lexer.parseObject();
      if (token == PdfToken.endOfInput) break;

      if (token is! PdfKeyword) {
        operands.add(token);
        // Operador legítimo nunca tem tantos operandos; o teto evita que
        // conteúdo corrompido cresça a lista sem limite.
        if (operands.length > 64) operands.removeAt(0);
        continue;
      }

      switch (token.value) {
        // ---------------------------------------------------- estado gráfico
        case 'q':
          state.push();
        case 'Q':
          state.pop();
        case 'cm':
          if (operands.length >= 6) {
            state.ctm = _multiply(_matrixOf(operands, 6), state.ctm);
          }

        // ------------------------------------------------------ estado texto
        case 'BT':
          state.tm = _identity();
          state.tlm = _identity();
        case 'ET':
          break;
        case 'Tf':
          if (operands.length >= 2) {
            final size = operands[operands.length - 1];
            final name = operands[operands.length - 2];
            if (size is num) state.fontSize = size.toDouble();
            if (name is String) state.font = _font(resources, name);
          }
        case 'TL':
          state.leading = _numberOf(operands, 0);
        case 'Tc':
          state.charSpace = _numberOf(operands, 0);
        case 'Tw':
          state.wordSpace = _numberOf(operands, 0);
        case 'Tz':
          final scale = _numberOf(operands, 100);
          if (scale != 0) state.hscale = scale / 100;
        case 'Ts':
          state.rise = _numberOf(operands, 0);

        // -------------------------------------------------- posicionamento
        case 'Td':
          if (operands.length >= 2) {
            state.nextLine(
              _numberAt(operands, operands.length - 2),
              _numberAt(operands, operands.length - 1),
            );
          }
        case 'TD':
          if (operands.length >= 2) {
            final ty = _numberAt(operands, operands.length - 1);
            state.leading = -ty;
            state.nextLine(_numberAt(operands, operands.length - 2), ty);
          }
        case 'Tm':
          if (operands.length >= 6) {
            state.tlm = _matrixOf(operands, 6);
            state.tm = List<double>.of(state.tlm);
          }
        case 'T*':
          state.nextLine(0, -state.leading);

        // -------------------------------------------------------- mostrar
        case 'Tj':
          if (operands.isNotEmpty) {
            _show(operands.last, state, out);
          }
        case 'TJ':
          if (operands.isNotEmpty) {
            _showArray(operands.last, state, out);
          }
        case "'":
          state.nextLine(0, -state.leading);
          if (operands.isNotEmpty) _show(operands.last, state, out);
        case '"':
          if (operands.length >= 3) {
            state.wordSpace = _numberAt(operands, operands.length - 3);
            state.charSpace = _numberAt(operands, operands.length - 2);
            state.nextLine(0, -state.leading);
            _show(operands.last, state, out);
          }

        // ----------------------------------------------------- objetos externos
        case 'Do':
          if (operands.isNotEmpty && operands.last is String) {
            _runForm(operands.last as String, resources, state, out, depth);
          }
        case 'BI':
          _skipInlineImage(lexer);
      }

      operands.clear();
    }
  }

  // ------------------------------------------------------------------ texto

  void _show(Object? operand, _State state, StringBuffer out) {
    if (operand is PdfString) _draw(operand.bytes, state, out);
  }

  void _showArray(Object? operand, _State state, StringBuffer out) {
    if (operand is! List) return;

    for (final item in operand) {
      if (item is PdfString) {
        _draw(item.bytes, state, out);
      } else if (item is num) {
        // Ajuste de kerning, em milésimos de em e com sinal invertido. Não
        // vira espaço aqui: o deslocamento entra na matriz e a decisão sai da
        // mesma régua geométrica que todo o resto usa.
        final tx = -item.toDouble() / 1000 * state.fontSize * state.hscale;
        state.tm = _multiply(_translation(tx, 0), state.tm);
      }
    }
  }

  void _draw(Uint8List bytes, _State state, StringBuffer out) {
    final font = state.font;
    if (font == null || bytes.isEmpty) return;

    final start = _renderMatrix(state);
    final startX = start[4];
    final startY = start[5];
    final size = math.max(_verticalScale(start), 0.0001);
    final gapScale = math.max(_horizontalScale(start), 0.0001);

    _separate(state, out, startX, startY, size, gapScale, font.metricsKnown);

    for (final code in font.codesOf(bytes)) {
      out.write(font.textOf(code));

      final advance =
          (font.widthOf(code) * state.fontSize +
              state.charSpace +
              (font.takesWordSpacing(code) ? state.wordSpace : 0)) *
          state.hscale;
      state.tm = _multiply(_translation(advance, 0), state.tm);
    }

    final end = _renderMatrix(state);
    state
      ..lastX = end[4]
      ..lastY = end[5]
      ..lastSize = size
      ..hasDrawn = true;
  }

  /// Decide se entra espaço, quebra de linha ou nada antes do próximo trecho.
  void _separate(
    _State state,
    StringBuffer out,
    double x,
    double y,
    double size,
    double gapScale,
    bool metricsKnown,
  ) {
    if (!state.hasDrawn) return;

    final reference = math.max(size, state.lastSize);

    // Mudou de altura, ou voltou muito à esquerda sem mudar: outra linha.
    // O segundo caso é o que separa colunas de uma tabela ou de um layout de
    // duas colunas, em que a altura se repete.
    if ((y - state.lastY).abs() > _lineRatio * reference ||
        x < state.lastX - _carriageRatio * reference) {
      if (!_endsWithBreak(out)) out.write('\n');
      return;
    }

    // Sem métrica confiável, `state.lastX` é chute e não serve de régua.
    if (!metricsKnown) return;

    if (x - state.lastX > _spaceRatio * gapScale && !_endsWithSpace(out)) {
      out.write(' ');
    }
  }

  static bool _endsWithBreak(StringBuffer out) {
    if (out.isEmpty) return true;
    final text = out.toString();
    return text.endsWith('\n');
  }

  static bool _endsWithSpace(StringBuffer out) {
    if (out.isEmpty) return true;
    final last = out.toString().codeUnitAt(out.length - 1);
    return last == 0x20 || last == 0x0A || last == 0x09;
  }

  // -------------------------------------------------------------- recursos

  PdfFont? _font(Map<String, Object?> resources, String name) {
    final fonts = _document.dictOf(resources['Font']);
    final entry = fonts?[name];
    if (entry == null) return null;

    // A chave é a referência quando existe: a mesma fonte aparece em toda
    // página, e reparsear o `/ToUnicode` de cada uma é o grosso do custo.
    final key = entry is PdfRef ? entry : '$name@${identityHashCode(fonts)}';

    final cached = _fonts[key];
    if (cached != null) return cached;

    final dict = _document.dictOf(entry);
    if (dict == null) return null;

    return _fonts[key] = PdfFont.load(_document, dict);
  }

  void _runForm(
    String name,
    Map<String, Object?> resources,
    _State state,
    StringBuffer out,
    int depth,
  ) {
    if (depth >= _maxFormDepth) return;

    final xobjects = _document.dictOf(resources['XObject']);
    final entry = xobjects?[name];
    if (entry == null) return;

    final stream = _document.resolve(entry);
    // Imagem não tem texto; só form importa aqui.
    if (stream is! PdfStream || stream.dict['Subtype'] != 'Form') return;

    final content = _document.streamBytes(entry);
    if (content == null || content.isEmpty) return;

    final inner = state.clone();

    // O `/Matrix` do form entra antes da CTM corrente.
    final matrix = _document.resolve(stream.dict['Matrix']);
    if (matrix is List && matrix.length >= 6) {
      inner.ctm = _multiply(_matrixOf(matrix, 6), inner.ctm);
    }

    // Form sem `/Resources` herda os de quem o desenhou.
    final formResources =
        _document.dictOf(stream.dict['Resources']) ?? resources;

    _run(content, formResources, inner, out, depth + 1);

    // A posição da caneta continua valendo: o texto do form e o da página
    // saem no mesmo buffer, e zerar aqui grudaria os dois.
    state
      ..lastX = inner.lastX
      ..lastY = inner.lastY
      ..lastSize = inner.lastSize
      ..hasDrawn = state.hasDrawn || inner.hasDrawn;
  }

  /// Pula uma imagem embutida (`BI ... ID <bytes> EI`).
  ///
  /// Os bytes entre `ID` e `EI` são binários crus e não seguem a sintaxe do
  /// content stream — deixar o lexer atravessá-los produziria operadores
  /// inventados a partir de pixel.
  static void _skipInlineImage(PdfLexer lexer) {
    // Primeiro os pares chave/valor, até `ID`.
    while (true) {
      final token = lexer.parseObject();
      if (token == PdfToken.endOfInput) return;
      if (token is PdfKeyword && token.value == 'ID') break;
    }

    // Um byte de separação depois de `ID`, e então procura `EI` isolado.
    if (!lexer.atEnd) lexer.pos++;

    while (lexer.pos + 1 < lexer.bytes.length) {
      if (lexer.bytes[lexer.pos] == 0x45 && // E
          lexer.bytes[lexer.pos + 1] == 0x49 && // I
          (lexer.pos == 0 ||
              PdfLexer.isWhitespace(lexer.bytes[lexer.pos - 1])) &&
          (lexer.pos + 2 >= lexer.bytes.length ||
              !PdfLexer.isRegular(lexer.bytes[lexer.pos + 2]))) {
        lexer.pos += 2;
        return;
      }
      lexer.pos++;
    }

    lexer.pos = lexer.bytes.length;
  }

  // -------------------------------------------------------------- matrizes

  /// Matriz de renderização: corpo e inclinação da fonte, sobre a matriz de
  /// texto, sobre a matriz corrente. É dela que saem as coordenadas usadas
  /// para decidir espaço e quebra de linha.
  static List<double> _renderMatrix(_State state) {
    final scaled = <double>[
      state.fontSize * state.hscale,
      0,
      0,
      state.fontSize,
      0,
      state.rise,
    ];
    return _multiply(_multiply(scaled, state.tm), state.ctm);
  }

  static double _horizontalScale(List<double> m) =>
      math.sqrt(m[0] * m[0] + m[1] * m[1]);

  static double _verticalScale(List<double> m) =>
      math.sqrt(m[2] * m[2] + m[3] * m[3]);

  static List<double> _identity() => <double>[1, 0, 0, 1, 0, 0];

  static List<double> _translation(double x, double y) => <double>[
    1,
    0,
    0,
    1,
    x,
    y,
  ];

  static List<double> _multiply(List<double> m, List<double> n) => <double>[
    m[0] * n[0] + m[1] * n[2],
    m[0] * n[1] + m[1] * n[3],
    m[2] * n[0] + m[3] * n[2],
    m[2] * n[1] + m[3] * n[3],
    m[4] * n[0] + m[5] * n[2] + n[4],
    m[4] * n[1] + m[5] * n[3] + n[5],
  ];

  /// Lê os [count] últimos operandos como matriz.
  static List<double> _matrixOf(List<Object?> operands, int count) {
    final start = operands.length - count;
    return List<double>.generate(count, (i) {
      final value = operands[start + i];
      return value is num ? value.toDouble() : 0;
    });
  }

  static double _numberOf(List<Object?> operands, double fallback) {
    if (operands.isEmpty) return fallback;
    final value = operands.last;
    return value is num ? value.toDouble() : fallback;
  }

  static double _numberAt(List<Object?> operands, int index) {
    if (index < 0 || index >= operands.length) return 0;
    final value = operands[index];
    return value is num ? value.toDouble() : 0;
  }
}

/// Estado gráfico e de texto durante a execução do content stream.
class _State {
  _State(this.resources);

  final Map<String, Object?> resources;

  List<double> ctm = <double>[1, 0, 0, 1, 0, 0];
  List<double> tm = <double>[1, 0, 0, 1, 0, 0];
  List<double> tlm = <double>[1, 0, 0, 1, 0, 0];

  PdfFont? font;
  double fontSize = 0;
  double charSpace = 0;
  double wordSpace = 0;
  double hscale = 1;
  double leading = 0;
  double rise = 0;

  /// Onde a caneta parou depois do último trecho desenhado.
  double lastX = 0;
  double lastY = 0;
  double lastSize = 0;
  bool hasDrawn = false;

  final List<_Saved> _stack = <_Saved>[];

  void push() {
    // `q`/`Q` salvam o estado gráfico. Matriz de texto fica de fora de
    // propósito: ela é reiniciada por `BT`, não pela pilha gráfica.
    _stack.add(
      _Saved(
        ctm: List<double>.of(ctm),
        font: font,
        fontSize: fontSize,
        charSpace: charSpace,
        wordSpace: wordSpace,
        hscale: hscale,
        leading: leading,
        rise: rise,
      ),
    );
    // `Q` sem `q` correspondente existe; o teto evita crescer sem limite.
    if (_stack.length > 64) _stack.removeAt(0);
  }

  void pop() {
    if (_stack.isEmpty) return;
    final saved = _stack.removeLast();
    ctm = saved.ctm;
    font = saved.font;
    fontSize = saved.fontSize;
    charSpace = saved.charSpace;
    wordSpace = saved.wordSpace;
    hscale = saved.hscale;
    leading = saved.leading;
    rise = saved.rise;
  }

  /// `Td`: abre uma linha deslocada em relação à anterior.
  void nextLine(double tx, double ty) {
    tlm = PdfTextExtractor._multiply(
      PdfTextExtractor._translation(tx, ty),
      tlm,
    );
    tm = List<double>.of(tlm);
  }

  _State clone() => _State(resources)
    ..ctm = List<double>.of(ctm)
    ..tm = List<double>.of(tm)
    ..tlm = List<double>.of(tlm)
    ..font = font
    ..fontSize = fontSize
    ..charSpace = charSpace
    ..wordSpace = wordSpace
    ..hscale = hscale
    ..leading = leading
    ..rise = rise
    ..lastX = lastX
    ..lastY = lastY
    ..lastSize = lastSize
    ..hasDrawn = hasDrawn;
}

class _Saved {
  const _Saved({
    required this.ctm,
    required this.font,
    required this.fontSize,
    required this.charSpace,
    required this.wordSpace,
    required this.hscale,
    required this.leading,
    required this.rise,
  });

  final List<double> ctm;
  final PdfFont? font;
  final double fontSize;
  final double charSpace;
  final double wordSpace;
  final double hscale;
  final double leading;
  final double rise;
}
