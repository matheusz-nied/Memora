/// Modelo de objeto PDF, mapeado nos tipos nativos do Dart sempre que dá.
///
/// | PDF               | Dart                   |
/// |-------------------|------------------------|
/// | `null`            | `null`                 |
/// | `true` / `false`  | `bool`                 |
/// | `42` / `3.14`     | `num`                  |
/// | `/Nome`           | `String`               |
/// | `(texto)` `<41>`  | [PdfString]            |
/// | `[ ... ]`         | `List<Object?>`        |
/// | `<< ... >>`       | `Map<String, Object?>` |
/// | `12 0 R`          | [PdfRef]               |
/// | `<<...>> stream`  | [PdfStream]            |
///
/// Nome vira `String` e string vira [PdfString] — e não o contrário — porque
/// nome é identificador (chave de dicionário, seletor de recurso, sempre
/// ASCII) enquanto string é carga de bytes cuja decodificação só é conhecida
/// pela fonte que a desenha. Trocar os dois faria o lexer decidir uma
/// codificação que ele não tem como saber.
library;

import 'dart:typed_data';

/// Referência indireta: `12 0 R`.
class PdfRef {
  const PdfRef(this.number, this.generation);

  final int number;
  final int generation;

  @override
  bool operator ==(Object other) =>
      other is PdfRef &&
      other.number == number &&
      other.generation == generation;

  @override
  int get hashCode => Object.hash(number, generation);

  @override
  String toString() => '$number $generation R';
}

/// Bytes crus de uma string do PDF, ainda sem codificação.
///
/// `(A)` pode ser a letra "A", o glifo 65 de uma fonte com `/Differences`
/// apontando para outro caractere, ou metade de um código de 2 bytes numa
/// fonte CID. Quem sabe traduzir é a fonte corrente do content stream, então o
/// lexer entrega os bytes intactos.
class PdfString {
  const PdfString(this.bytes);

  final Uint8List bytes;

  /// Interpreta os bytes como texto simples, do jeito que o PDF faz com
  /// metadados: UTF-16BE quando há BOM, PDFDocEncoding (≈Latin-1) caso
  /// contrário. Não serve para conteúdo de página — lá quem manda é a fonte.
  String asText() {
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final buffer = StringBuffer();
      for (var i = 2; i + 1 < bytes.length; i += 2) {
        buffer.writeCharCode((bytes[i] << 8) | bytes[i + 1]);
      }
      return buffer.toString();
    }
    return String.fromCharCodes(bytes);
  }

  @override
  String toString() => '(${asText()})';
}

/// Dicionário seguido de bytes codificados.
///
/// [raw] é o conteúdo como está no arquivo — passar por `PdfFilters.decode`
/// para obter os bytes de verdade.
class PdfStream {
  const PdfStream(this.dict, this.raw);

  final Map<String, Object?> dict;
  final Uint8List raw;

  @override
  String toString() => 'PdfStream(${dict.keys.join(', ')}, ${raw.length}B)';
}

/// Palavra nua do arquivo (`obj`, `endstream`, `n`, `f`) ou operador de content
/// stream (`Tj`, `BT`, `Do`).
///
/// Tipo próprio, e não `String`, porque `String` já representa `/Nome`: sem a
/// distinção, o operador `Do` e o nome `/Do` seriam o mesmo valor e o
/// interpretador de conteúdo executaria os próprios argumentos.
class PdfKeyword {
  const PdfKeyword(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is PdfKeyword && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Marcadores que não são objeto nenhum, e por isso não podem ser `null` — em
/// PDF `null` é um objeto legítimo, e confundir os dois faz um array com
/// `null` dentro terminar cedo.
enum PdfToken {
  /// Acabaram os bytes.
  endOfInput,

  /// `]` sem `[` correspondente aberto por quem chamou.
  arrayEnd,

  /// `>>` sem `<<` correspondente aberto por quem chamou.
  dictEnd,
}
