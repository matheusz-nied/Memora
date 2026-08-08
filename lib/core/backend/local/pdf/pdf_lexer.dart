import 'dart:typed_data';

import 'pdf_objects.dart';

/// Leitor de sintaxe PDF: transforma bytes em objetos ([pdf_objects.dart]).
///
/// Serve tanto para o corpo do arquivo quanto para content streams — a
/// gramática é a mesma, muda só o que aparece: no arquivo, `12 0 obj ... endobj`;
/// no conteúdo, operandos seguidos de um operador. Por isso [parseObject]
/// devolve [PdfKeyword] para qualquer palavra nua em vez de tratá-la como erro.
///
/// O lexer é deliberadamente tolerante. PDF gerado por impressora virtual,
/// scanner ou biblioteca antiga viola a especificação com frequência, e recusar
/// o arquivo inteiro por causa de um `/Length` errado desperdiça um documento
/// que seria perfeitamente legível.
class PdfLexer {
  PdfLexer(this.bytes, [this.pos = 0]);

  final Uint8List bytes;
  int pos;

  bool get atEnd => pos >= bytes.length;

  // ---------------------------------------------------------------- caracteres

  static bool isWhitespace(int c) =>
      c == 0x20 || // espaço
      c == 0x0A || // LF
      c == 0x0D || // CR
      c == 0x09 || // TAB
      c == 0x0C || // FF
      c == 0x00; // NUL

  static bool isDelimiter(int c) =>
      c == 0x28 || // (
      c == 0x29 || // )
      c == 0x3C || // <
      c == 0x3E || // >
      c == 0x5B || // [
      c == 0x5D || // ]
      c == 0x7B || // {
      c == 0x7D || // }
      c == 0x2F || // /
      c == 0x25; // %

  static bool isRegular(int c) => !isWhitespace(c) && !isDelimiter(c);

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  static int _hexValue(int c) {
    if (c >= 0x30 && c <= 0x39) return c - 0x30;
    if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;
    if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
    return -1;
  }

  // -------------------------------------------------------------- navegação

  void skipWhitespace() {
    while (pos < bytes.length) {
      final c = bytes[pos];
      if (isWhitespace(c)) {
        pos++;
      } else if (c == 0x25) {
        // `%` comenta até o fim da linha.
        while (pos < bytes.length && bytes[pos] != 0x0A && bytes[pos] != 0x0D) {
          pos++;
        }
      } else {
        return;
      }
    }
  }

  /// Consome o fim de linha logo após uma palavra-chave (`stream`, `ID`).
  void skipEol() {
    if (pos < bytes.length && bytes[pos] == 0x0D) pos++;
    if (pos < bytes.length && bytes[pos] == 0x0A) pos++;
  }

  /// Verifica se [word] começa em [pos] sem consumir nada.
  bool matches(String word) {
    if (pos + word.length > bytes.length) return false;
    for (var i = 0; i < word.length; i++) {
      if (bytes[pos + i] != word.codeUnitAt(i)) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------- objetos

  /// Lê o próximo objeto.
  ///
  /// Devolve [PdfToken.endOfInput] no fim dos bytes, e [PdfToken.arrayEnd] ou
  /// [PdfToken.dictEnd] quando encontra um fechamento que não abriu.
  Object? parseObject() {
    skipWhitespace();
    if (atEnd) return PdfToken.endOfInput;

    final c = bytes[pos];

    switch (c) {
      case 0x2F: // /
        return _parseName();
      case 0x28: // (
        return _parseLiteralString();
      case 0x5B: // [
        pos++;
        return _parseArray();
      case 0x5D: // ]
        pos++;
        return PdfToken.arrayEnd;
      case 0x3C: // < ou <<
        if (pos + 1 < bytes.length && bytes[pos + 1] == 0x3C) {
          pos += 2;
          return _parseDictOrStream();
        }
        return _parseHexString();
      case 0x3E: // >>
        pos += (pos + 1 < bytes.length && bytes[pos + 1] == 0x3E) ? 2 : 1;
        return PdfToken.dictEnd;
      case 0x7B: // { — só aparece em função PostScript; devolvemos como palavra
      case 0x7D: // }
        pos++;
        return PdfKeyword(String.fromCharCode(c));
      case 0x29: // ) órfão: byte solto de arquivo corrompido
        pos++;
        return parseObject();
    }

    if (_isDigit(c) || c == 0x2B || c == 0x2D || c == 0x2E) {
      return _parseNumberOrRef();
    }

    return _parseKeyword();
  }

  String _parseName() {
    pos++; // consome `/`
    final out = <int>[];
    while (pos < bytes.length && isRegular(bytes[pos])) {
      var b = bytes[pos];
      // `#41` é um `A` escapado — usado quando o nome tem caractere especial.
      if (b == 0x23 && pos + 2 < bytes.length) {
        final hi = _hexValue(bytes[pos + 1]);
        final lo = _hexValue(bytes[pos + 2]);
        if (hi >= 0 && lo >= 0) {
          b = (hi << 4) | lo;
          pos += 2;
        }
      }
      out.add(b);
      pos++;
    }
    return String.fromCharCodes(out);
  }

  PdfString _parseLiteralString() {
    pos++; // consome `(`
    final out = <int>[];
    var depth = 1;

    while (pos < bytes.length) {
      final c = bytes[pos++];

      if (c == 0x5C) {
        // barra invertida
        if (pos >= bytes.length) break;
        final e = bytes[pos++];
        switch (e) {
          case 0x6E:
            out.add(0x0A); // \n
          case 0x72:
            out.add(0x0D); // \r
          case 0x74:
            out.add(0x09); // \t
          case 0x62:
            out.add(0x08); // \b
          case 0x66:
            out.add(0x0C); // \f
          case 0x28:
          case 0x29:
          case 0x5C:
            out.add(e); // \( \) \\
          case 0x0D:
            // Quebra de linha escapada: a linha continua, nada entra na string.
            if (pos < bytes.length && bytes[pos] == 0x0A) pos++;
          case 0x0A:
            break;
          default:
            if (e >= 0x30 && e <= 0x37) {
              // \ddd octal, de 1 a 3 dígitos.
              var value = e - 0x30;
              for (var i = 0; i < 2; i++) {
                if (pos < bytes.length &&
                    bytes[pos] >= 0x30 &&
                    bytes[pos] <= 0x37) {
                  value = value * 8 + (bytes[pos++] - 0x30);
                } else {
                  break;
                }
              }
              out.add(value & 0xFF);
            } else {
              // Escape desconhecido: a especificação manda ignorar a barra.
              out.add(e);
            }
        }
        continue;
      }

      if (c == 0x28) {
        depth++;
        out.add(c);
      } else if (c == 0x29) {
        depth--;
        if (depth == 0) break;
        out.add(c);
      } else if (c == 0x0D) {
        // CR e CRLF crus viram LF, conforme a especificação.
        if (pos < bytes.length && bytes[pos] == 0x0A) pos++;
        out.add(0x0A);
      } else {
        out.add(c);
      }
    }

    return PdfString(Uint8List.fromList(out));
  }

  PdfString _parseHexString() {
    pos++; // consome `<`
    final out = <int>[];
    var high = -1;

    while (pos < bytes.length) {
      final c = bytes[pos++];
      if (c == 0x3E) break; // >
      final v = _hexValue(c);
      if (v < 0) continue; // espaços e lixo são ignorados dentro do hex
      if (high < 0) {
        high = v;
      } else {
        out.add((high << 4) | v);
        high = -1;
      }
    }

    // Dígito ímpar no fim: a especificação manda completar com zero.
    if (high >= 0) out.add(high << 4);

    return PdfString(Uint8List.fromList(out));
  }

  List<Object?> _parseArray() {
    final out = <Object?>[];
    while (true) {
      final item = parseObject();
      if (item == PdfToken.arrayEnd || item == PdfToken.endOfInput) break;
      // `>>` dentro de array é arquivo quebrado; parar aqui evita engolir o
      // resto do documento como se fosse conteúdo do array.
      if (item == PdfToken.dictEnd) break;
      out.add(item);
    }
    return out;
  }

  Object? _parseDictOrStream() {
    final dict = <String, Object?>{};

    while (true) {
      skipWhitespace();
      if (atEnd) break;

      if (bytes[pos] == 0x3E) {
        pos += (pos + 1 < bytes.length && bytes[pos + 1] == 0x3E) ? 2 : 1;
        break;
      }

      final key = parseObject();
      if (key == PdfToken.endOfInput || key == PdfToken.dictEnd) break;
      // Chave tem que ser nome. Qualquer outra coisa é lixo: descarta e segue,
      // em vez de abandonar um dicionário que ainda tem pares válidos.
      if (key is! String) continue;

      final value = parseObject();
      if (value == PdfToken.endOfInput) break;
      if (value == PdfToken.dictEnd || value == PdfToken.arrayEnd) break;
      dict[key] = value;
    }

    // `stream` logo depois do dicionário transforma o par em PdfStream.
    final afterDict = pos;
    skipWhitespace();
    if (matches('stream')) {
      pos += 'stream'.length;
      skipEol();
      return PdfStream(dict, _readStreamBody(dict));
    }
    pos = afterDict;
    return dict;
  }

  /// Extrai o corpo do stream a partir da posição corrente.
  ///
  /// Prefere o `/Length` declarado, mas só quando ele leva mesmo a um
  /// `endstream` — `/Length` errado ou indireto é comum o bastante para que
  /// confiar nele cegamente perca páginas inteiras. Quando não confere, varre
  /// até o `endstream`, que é o que os leitores de verdade fazem.
  Uint8List _readStreamBody(Map<String, Object?> dict) {
    final start = pos;
    final declared = dict['Length'];

    if (declared is int && declared >= 0 && start + declared <= bytes.length) {
      final probe = PdfLexer(bytes, start + declared)..skipWhitespace();
      if (probe.matches('endstream')) {
        pos = probe.pos + 'endstream'.length;
        return Uint8List.sublistView(bytes, start, start + declared);
      }
    }

    final end = _findKeyword('endstream', start);
    if (end < 0) {
      pos = bytes.length;
      return Uint8List.sublistView(bytes, start);
    }

    // O EOL que antecede `endstream` é delimitador, não conteúdo.
    var stop = end;
    if (stop > start && bytes[stop - 1] == 0x0A) stop--;
    if (stop > start && bytes[stop - 1] == 0x0D) stop--;

    pos = end + 'endstream'.length;
    return Uint8List.sublistView(bytes, start, stop);
  }

  int _findKeyword(String word, int from) {
    final first = word.codeUnitAt(0);
    final limit = bytes.length - word.length;
    for (var i = from; i <= limit; i++) {
      if (bytes[i] != first) continue;
      var hit = true;
      for (var j = 1; j < word.length; j++) {
        if (bytes[i + j] != word.codeUnitAt(j)) {
          hit = false;
          break;
        }
      }
      if (hit) return i;
    }
    return -1;
  }

  /// Lê um número e, quando ele for a cabeça de `num gen R`, uma referência.
  Object? _parseNumberOrRef() {
    final value = _parseNumber();

    if (value is! int || value < 0) return value;

    // `12 0 R` só é referência se os três tokens estiverem lá. Se não
    // estiverem, o `12` era um número comum e a posição precisa voltar.
    final save = pos;
    skipWhitespace();
    if (!atEnd && _isDigit(bytes[pos])) {
      final generation = _parseNumber();
      if (generation is int && generation >= 0) {
        skipWhitespace();
        if (matches('R') &&
            (pos + 1 >= bytes.length || !isRegular(bytes[pos + 1]))) {
          pos++;
          return PdfRef(value, generation);
        }
      }
    }
    pos = save;
    return value;
  }

  num _parseNumber() {
    final start = pos;
    var seenDot = false;
    var seenDigit = false;

    if (!atEnd && (bytes[pos] == 0x2B || bytes[pos] == 0x2D)) pos++;

    while (pos < bytes.length) {
      final c = bytes[pos];
      if (_isDigit(c)) {
        seenDigit = true;
        pos++;
      } else if (c == 0x2E && !seenDot) {
        seenDot = true;
        pos++;
      } else if (c == 0x2D || c == 0x2B) {
        // `--5` e `1-2` aparecem em arquivos gerados por software ruim; o sinal
        // extra é ruído, não separador.
        pos++;
      } else {
        break;
      }
    }

    if (!seenDigit) {
      // Só sinal ou ponto solto: consome para não travar o laço e vale zero.
      if (pos == start) pos++;
      return 0;
    }

    final text = String.fromCharCodes(bytes, start, pos);
    if (!seenDot) {
      final parsed = int.tryParse(text);
      if (parsed != null) return parsed;
    }
    return double.tryParse(text) ?? 0;
  }

  Object? _parseKeyword() {
    final start = pos;
    while (pos < bytes.length && isRegular(bytes[pos])) {
      pos++;
    }

    // Byte que não é regular nem foi tratado acima: pula para não travar.
    if (pos == start) {
      pos++;
      return parseObject();
    }

    final word = String.fromCharCodes(bytes, start, pos);
    return switch (word) {
      'true' => true,
      'false' => false,
      'null' => null,
      _ => PdfKeyword(word),
    };
  }
}
