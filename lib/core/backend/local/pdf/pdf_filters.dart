import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'pdf_objects.dart';

/// Decodificadores de stream do PDF.
///
/// Cobre os filtros que carregam **texto** — `FlateDecode` responde por quase
/// tudo que interessa aqui (content streams, object streams, xref streams e
/// CMaps de `/ToUnicode`), e os outros quatro aparecem em arquivos antigos.
/// Filtros de imagem (`DCTDecode`, `JPXDecode`, `CCITTFaxDecode`, `JBIG2Decode`)
/// são deixados intactos de propósito: nunca precisamos dos pixels, e tentar
/// decodificá-los só gastaria CPU num aparelho.
abstract final class PdfFilters {
  /// Aplica a cadeia de `/Filter` de [stream], na ordem declarada.
  ///
  /// [resolve] existe porque `/Filter`, `/DecodeParms` e os parâmetros
  /// individuais podem ser referências indiretas.
  static Uint8List decode(PdfStream stream, Object? Function(Object?) resolve) {
    final filters = _asList(
      resolve(stream.dict['Filter']) ?? resolve(stream.dict['F']),
    );
    if (filters.isEmpty) return stream.raw;

    final parms = _asList(
      resolve(stream.dict['DecodeParms']) ?? resolve(stream.dict['DP']),
    );

    var data = stream.raw;
    for (var i = 0; i < filters.length; i++) {
      final name = resolve(filters[i]);
      if (name is! String) continue;

      final parm = i < parms.length ? resolve(parms[i]) : null;
      final options = parm is Map<String, Object?> ? parm : null;

      data = _applyOne(name, data, options, resolve);
    }
    return data;
  }

  static Uint8List _applyOne(
    String name,
    Uint8List data,
    Map<String, Object?>? parms,
    Object? Function(Object?) resolve,
  ) {
    switch (name) {
      case 'FlateDecode':
      case 'Fl':
        return _predict(_inflate(data), parms, resolve);
      case 'LZWDecode':
      case 'LZW':
        final early = _intOf(resolve(parms?['EarlyChange']), 1);
        return _predict(_lzw(data, early), parms, resolve);
      case 'ASCIIHexDecode':
      case 'AHx':
        return _asciiHex(data);
      case 'ASCII85Decode':
      case 'A85':
        return _ascii85(data);
      case 'RunLengthDecode':
      case 'RL':
        return _runLength(data);
      default:
        // `Crypt` com `/Name /Identity` é no-op, e filtro de imagem a gente não
        // decodifica. Nos dois casos os bytes seguem como estão.
        return data;
    }
  }

  // ------------------------------------------------------------------ flate

  static Uint8List _inflate(Uint8List data) {
    // Alguns geradores põem lixo (espaço, EOL) antes do cabeçalho zlib.
    var start = 0;
    while (start < data.length && _isWhitespaceByte(data[start])) {
      start++;
    }
    final trimmed = start == 0 ? data : Uint8List.sublistView(data, start);
    if (trimmed.isEmpty) return Uint8List(0);

    try {
      return const ZLibDecoder().decodeBytes(trimmed);
    } catch (_) {
      // Cabeçalho zlib ausente ou corrompido. Duas tentativas valem a pena
      // porque as duas variantes existem no mundo real: deflate cru (gerador
      // que esqueceu o cabeçalho) e um byte a mais na frente.
      for (final attempt in <Uint8List Function()>[
        () => const ZLibDecoder().decodeBytes(trimmed, raw: true),
        () => const ZLibDecoder().decodeBytes(
          Uint8List.sublistView(trimmed, 1),
          raw: true,
        ),
      ]) {
        try {
          return attempt();
        } catch (_) {
          continue;
        }
      }
      // Stream truncado ainda pode ter conteúdo útil antes do corte — é o caso
      // típico de PDF baixado pela metade. Devolver vazio descartaria a página
      // inteira, então tentamos salvar o prefixo.
      return _inflatePartial(trimmed);
    }
  }

  /// Inflate tolerante a fim de dados: devolve o que deu para descomprimir
  /// antes do erro. Vale só para stream truncado, e por isso é o último
  /// recurso — o caminho normal é o [ZLibDecoder] acima.
  static Uint8List _inflatePartial(Uint8List data) {
    // Vai cortando o fim: um bloco deflate incompleto falha, mas os blocos
    // anteriores já fecharam e descomprimem sozinhos.
    for (var cut = data.length; cut > 64; cut -= (data.length ~/ 16) + 1) {
      for (final raw in const [false, true]) {
        try {
          final out = const ZLibDecoder().decodeBytes(
            Uint8List.sublistView(data, 0, cut),
            raw: raw,
          );
          if (out.isNotEmpty) return out;
        } catch (_) {
          continue;
        }
      }
    }
    return Uint8List(0);
  }

  // -------------------------------------------------------------------- lzw

  static Uint8List _lzw(Uint8List data, int earlyChange) {
    const clearCode = 256;
    const eodCode = 257;

    final out = BytesBuilder(copy: false);
    var table = <List<int>>[];

    void resetTable() {
      table = List<List<int>>.generate(
        258,
        (i) => i < 256 ? <int>[i] : <int>[],
      );
    }

    resetTable();
    var codeWidth = 9;
    var previous = <int>[];
    var buffer = 0;
    var bits = 0;

    for (final byte in data) {
      buffer = (buffer << 8) | byte;
      bits += 8;

      while (bits >= codeWidth) {
        final code = (buffer >> (bits - codeWidth)) & ((1 << codeWidth) - 1);
        bits -= codeWidth;

        if (code == eodCode) return out.takeBytes();

        if (code == clearCode) {
          resetTable();
          codeWidth = 9;
          previous = <int>[];
          continue;
        }

        List<int> entry;
        if (code < table.length) {
          entry = table[code];
          if (previous.isNotEmpty) {
            table.add(<int>[...previous, entry.first]);
          }
        } else if (previous.isNotEmpty) {
          // Código ainda não na tabela: é o caso KwKwK do LZW, em que o
          // dicionário só ganha a entrada no mesmo passo em que ela é usada.
          entry = <int>[...previous, previous.first];
          table.add(entry);
        } else {
          return out.takeBytes(); // fluxo inválido
        }

        out.add(entry);
        previous = entry;

        // `EarlyChange` = 1 (padrão) alarga o código uma posição antes.
        final limit = table.length + earlyChange;
        if (limit >= 512 && codeWidth == 9) {
          codeWidth = 10;
        } else if (limit >= 1024 && codeWidth == 10) {
          codeWidth = 11;
        } else if (limit >= 2048 && codeWidth == 11) {
          codeWidth = 12;
        }
      }
    }

    return out.takeBytes();
  }

  // ------------------------------------------------------------------ ascii

  static Uint8List _asciiHex(Uint8List data) {
    final out = BytesBuilder(copy: false);
    var high = -1;

    for (final c in data) {
      if (c == 0x3E) break; // `>` encerra
      final v = switch (c) {
        >= 0x30 && <= 0x39 => c - 0x30,
        >= 0x41 && <= 0x46 => c - 0x41 + 10,
        >= 0x61 && <= 0x66 => c - 0x61 + 10,
        _ => -1,
      };
      if (v < 0) continue;
      if (high < 0) {
        high = v;
      } else {
        out.addByte((high << 4) | v);
        high = -1;
      }
    }

    if (high >= 0) out.addByte(high << 4);
    return out.takeBytes();
  }

  static Uint8List _ascii85(Uint8List data) {
    final out = BytesBuilder(copy: false);
    var group = 0;
    var count = 0;
    var i = 0;

    // O prefixo `<~` é opcional e nem todo gerador escreve.
    if (data.length >= 2 && data[0] == 0x3C && data[1] == 0x7E) i = 2;

    for (; i < data.length; i++) {
      final c = data[i];
      if (_isWhitespaceByte(c)) continue;
      if (c == 0x7E) break; // `~>` encerra

      if (c == 0x7A && count == 0) {
        out.add(const [0, 0, 0, 0]); // `z` abrevia quatro zeros
        continue;
      }

      if (c < 0x21 || c > 0x75) continue; // fora de `!`..`u`: lixo

      group = group * 85 + (c - 0x21);
      count++;

      if (count == 5) {
        out
          ..addByte((group >> 24) & 0xFF)
          ..addByte((group >> 16) & 0xFF)
          ..addByte((group >> 8) & 0xFF)
          ..addByte(group & 0xFF);
        group = 0;
        count = 0;
      }
    }

    // Grupo final incompleto: completa com `u` e descarta os bytes sobrando.
    if (count > 1) {
      for (var j = count; j < 5; j++) {
        group = group * 85 + 84;
      }
      for (var j = 0; j < count - 1; j++) {
        out.addByte((group >> (24 - j * 8)) & 0xFF);
      }
    }

    return out.takeBytes();
  }

  static Uint8List _runLength(Uint8List data) {
    final out = BytesBuilder(copy: false);
    var i = 0;

    while (i < data.length) {
      final length = data[i++];
      if (length == 128) break; // EOD
      if (length < 128) {
        final end = (i + length + 1).clamp(0, data.length);
        out.add(Uint8List.sublistView(data, i, end));
        i = end;
      } else {
        if (i >= data.length) break;
        final byte = data[i++];
        for (var j = 0; j < 257 - length; j++) {
          out.addByte(byte);
        }
      }
    }

    return out.takeBytes();
  }

  // ------------------------------------------------------------- preditores

  /// Desfaz a predição aplicada antes da compressão.
  ///
  /// Xref streams sempre usam preditor PNG, então sem isto o arquivo moderno
  /// médio nem abre.
  static Uint8List _predict(
    Uint8List data,
    Map<String, Object?>? parms,
    Object? Function(Object?) resolve,
  ) {
    if (parms == null) return data;

    final predictor = _intOf(resolve(parms['Predictor']), 1);
    if (predictor <= 1) return data;

    final colors = _intOf(resolve(parms['Colors']), 1);
    final bpc = _intOf(resolve(parms['BitsPerComponent']), 8);
    final columns = _intOf(resolve(parms['Columns']), 1);

    if (colors <= 0 || bpc <= 0 || columns <= 0) return data;

    final bpp = ((colors * bpc) + 7) ~/ 8; // bytes por pixel, mínimo 1
    final rowLength = ((colors * bpc * columns) + 7) ~/ 8;
    if (rowLength <= 0) return data;

    return predictor == 2
        ? _tiffPredictor(data, colors, bpc, rowLength)
        : _pngPredictor(data, bpp < 1 ? 1 : bpp, rowLength);
  }

  static Uint8List _pngPredictor(Uint8List data, int bpp, int rowLength) {
    final rows = data.length ~/ (rowLength + 1);
    final out = Uint8List(rows * rowLength);
    var prior = Uint8List(rowLength);

    for (var r = 0; r < rows; r++) {
      final inStart = r * (rowLength + 1);
      final type = data[inStart];
      final outStart = r * rowLength;

      for (var i = 0; i < rowLength; i++) {
        final raw = data[inStart + 1 + i];
        final left = i >= bpp ? out[outStart + i - bpp] : 0;
        final up = prior[i];

        final value = switch (type) {
          1 => raw + left, // Sub
          2 => raw + up, // Up
          3 => raw + ((left + up) >> 1), // Average
          4 => raw + _paeth(left, up, i >= bpp ? prior[i - bpp] : 0), // Paeth
          _ => raw, // None, e qualquer tipo inválido
        };
        out[outStart + i] = value & 0xFF;
      }

      prior = Uint8List.sublistView(out, outStart, outStart + rowLength);
    }

    return out;
  }

  static int _paeth(int a, int b, int c) {
    final p = a + b - c;
    final pa = (p - a).abs();
    final pb = (p - b).abs();
    final pc = (p - c).abs();
    if (pa <= pb && pa <= pc) return a;
    return pb <= pc ? b : c;
  }

  static Uint8List _tiffPredictor(
    Uint8List data,
    int colors,
    int bpc,
    int rowLength,
  ) {
    // Só o caso de 8 bits por componente, que é o único que aparece em PDF.
    // Fora dele, devolver os bytes intactos erra menos do que adivinhar.
    if (bpc != 8) return data;

    final out = Uint8List.fromList(data);
    final rows = out.length ~/ rowLength;

    for (var r = 0; r < rows; r++) {
      final start = r * rowLength;
      for (var i = colors; i < rowLength; i++) {
        out[start + i] = (out[start + i] + out[start + i - colors]) & 0xFF;
      }
    }

    return out;
  }

  // ----------------------------------------------------------------- apoio

  static bool _isWhitespaceByte(int c) =>
      c == 0x20 ||
      c == 0x0A ||
      c == 0x0D ||
      c == 0x09 ||
      c == 0x0C ||
      c == 0x00;

  static List<Object?> _asList(Object? value) => switch (value) {
    null => const [],
    final List<Object?> list => list,
    _ => [value],
  };

  static int _intOf(Object? value, int fallback) =>
      value is num ? value.toInt() : fallback;
}
