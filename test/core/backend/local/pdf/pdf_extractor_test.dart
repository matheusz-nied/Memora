import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/local/pdf/pdf_extractor.dart';

/// Testes do extrator contra PDFs montados byte a byte.
///
/// O teste do gateway já cobre o caminho moderno, porque o pacote `pdf` grava
/// na versão 1.5. O que sobra e importa está aqui: xref clássico, xref
/// quebrado, CMap de `/ToUnicode`, `/Differences` e form XObject. São
/// construções que um gerador específico produz e que, se falharem, falham em
/// silêncio — devolvendo texto vazio ou letra trocada, nunca uma exceção.
void main() {
  /// Monta um PDF com xref clássico e os objetos numerados a partir de 1.
  Uint8List assemble(
    List<String> objects, {
    String trailer = '/Root 1 0 R',
    bool corruptXref = false,
  }) {
    final out = BytesBuilder();
    void write(String text) => out.add(utf8.encode(text));

    write('%PDF-1.4\n');

    final offsets = <int>[];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(out.length);
      write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }

    final xrefAt = out.length;
    write('xref\n0 ${objects.length + 1}\n');
    write('0000000000 65535 f \n');
    for (final offset in offsets) {
      // Deslocar o offset simula o caso mais comum de arquivo remendado: a
      // tabela aponta para o meio de outro objeto.
      final value = corruptXref ? offset + 500 : offset;
      write('${value.toString().padLeft(10, '0')} 00000 n \n');
    }

    write(
      'trailer\n<< /Size ${objects.length + 1} $trailer >>\n'
      'startxref\n$xrefAt\n%%EOF\n',
    );

    return out.takeBytes();
  }

  String streamObject(String dict, String content) =>
      '<< $dict /Length ${utf8.encode(content).length} >>\n'
      'stream\n$content\nendstream';

  /// Documento de uma página com uma fonte e um content stream.
  Uint8List onePage(
    String content, {
    String font =
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>',
    String extraResources = '',
    List<String> extraObjects = const [],
    String trailer = '/Root 1 0 R',
    bool corruptXref = false,
  }) {
    return assemble(
      [
        '<< /Type /Catalog /Pages 2 0 R >>',
        '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
            '/Resources << /Font << /F1 4 0 R >> $extraResources >> '
            '/Contents 5 0 R >>',
        font,
        streamObject('', content),
        ...extraObjects,
      ],
      trailer: trailer,
      corruptXref: corruptXref,
    );
  }

  test('lê um PDF com xref clássico e stream sem compressão', () {
    final result = extractPdfText(
      onePage('BT /F1 12 Tf 72 720 Td (Fotossintese converte luz) Tj ET'),
    );

    expect(result.pages, 1);
    expect(result.text, 'Fotossintese converte luz');
  });

  test('abre o arquivo mesmo com a tabela xref apontando errado', () {
    final result = extractPdfText(
      onePage(
        'BT /F1 12 Tf 72 720 Td (Tabela quebrada nao impede a leitura) Tj ET',
        corruptXref: true,
      ),
    );

    // É o caminho da varredura bruta: sem ele, este arquivo não abriria.
    expect(result.text, 'Tabela quebrada nao impede a leitura');
  });

  test('insere espaço onde o PDF usou deslocamento em vez de caractere', () {
    // Nenhum espaço no conteúdo: a separação é só o ajuste de -2000 milésimos.
    final result = extractPdfText(
      onePage('BT /F1 12 Tf 72 720 Td [(Palavra)-2000(seguinte)] TJ ET'),
    );

    expect(result.text, 'Palavra seguinte');
  });

  test('não inventa espaço dentro de uma palavra ajustada por kerning', () {
    // -20 milésimos é kerning tipográfico normal entre duas letras.
    final result = extractPdfText(
      onePage('BT /F1 12 Tf 72 720 Td [(Va)-20(lor)] TJ ET'),
    );

    expect(result.text, 'Valor');
  });

  test('quebra a linha quando o texto desce na página', () {
    final result = extractPdfText(
      onePage(
        'BT /F1 12 Tf 72 720 Td (Primeira linha) Tj '
        '0 -20 Td (Segunda linha) Tj ET',
      ),
    );

    expect(result.text, 'Primeira linha\nSegunda linha');
  });

  test('usa /ToUnicode para decodificar fonte composta', () {
    const cmap =
        '/CIDInit /ProcSet findresource begin\n'
        '12 dict begin\nbegincmap\n'
        '1 begincodespacerange\n<0000> <FFFF>\nendcodespacerange\n'
        '3 beginbfchar\n<0001> <0043>\n<0002> <0041>\n<0003> <0053>\n'
        'endbfchar\n'
        'endcmap\nend\nend';

    final result = extractPdfText(
      onePage(
        'BT /F1 12 Tf 72 720 Td <000100020003> Tj ET',
        font:
            '<< /Type /Font /Subtype /Type0 /BaseFont /Sub+Fonte '
            '/Encoding /Identity-H /ToUnicode 6 0 R '
            '/DescendantFonts [<< /Type /Font /Subtype /CIDFontType2 '
            '/BaseFont /Sub+Fonte /DW 600 '
            '/CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) '
            '/Supplement 0 >> >>] >>',
        extraObjects: [streamObject('', cmap)],
      ),
    );

    // Sem o CMap, os códigos 1/2/3 não significam nada — é exatamente o caso
    // de fonte com subconjunto embutido, que é o que LaTeX e Word geram.
    expect(result.text, 'CAS');
  });

  test('aplica /Differences sobre a codificação base', () {
    final result = extractPdfText(
      onePage(
        'BT /F1 12 Tf 72 720 Td (AB) Tj ET',
        font:
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
            '/Encoding << /BaseEncoding /WinAnsiEncoding '
            '/Differences [65 /bullet /eacute] >> >>',
      ),
    );

    expect(result.text, '•é');
  });

  test('lê o texto que está dentro de um form XObject', () {
    const inner = 'BT /F1 12 Tf 0 50 Td (Texto dentro do form) Tj ET';

    final result = extractPdfText(
      onePage(
        'q 1 0 0 1 72 600 cm /Fm1 Do Q',
        extraResources: '/XObject << /Fm1 6 0 R >>',
        extraObjects: [
          streamObject(
            '/Type /XObject /Subtype /Form /BBox [0 0 300 100] '
            '/Resources << /Font << /F1 4 0 R >> >>',
            inner,
          ),
        ],
      ),
    );

    expect(result.text, 'Texto dentro do form');
  });

  test('ignora os bytes binários de uma imagem embutida', () {
    // `BI ... ID <binário> EI` não segue a sintaxe do content stream. Se o
    // lexer atravessar os bytes, ele inventa operador a partir de pixel.
    final result = extractPdfText(
      onePage(
        'q BI /W 2 /H 2 /CS /G /BPC 8 ID (Tj EI Q '
        'BT /F1 12 Tf 72 720 Td (Depois da imagem) Tj ET',
      ),
    );

    expect(result.text, 'Depois da imagem');
  });

  test('junta as páginas com uma linha em branco entre elas', () {
    final bytes = assemble([
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R 6 0 R] /Count 2 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
          '/Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
          '/Encoding /WinAnsiEncoding >>',
      streamObject('', 'BT /F1 12 Tf 72 720 Td (Pagina um) Tj ET'),
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
          '/Resources << /Font << /F1 4 0 R >> >> /Contents 7 0 R >>',
      streamObject('', 'BT /F1 12 Tf 72 720 Td (Pagina dois) Tj ET'),
    ]);

    final result = extractPdfText(bytes);

    expect(result.pages, 2);
    expect(result.text, 'Pagina um\n\nPagina dois');
  });

  test('respeita o teto de páginas sem extrair texto à toa', () {
    final result = extractPdfText(
      onePage('BT /F1 12 Tf 72 720 Td (Nao deveria sair) Tj ET'),
      maxPages: 0,
    );

    expect(result.pages, 1);
    expect(result.text, isEmpty);
  });

  test('PDF criptografado falha com motivo explícito', () {
    // Sem suporte a criptografia, seguir adiante decodificaria ruído e o
    // usuário veria "PDF sem texto" — que o manda procurar o arquivo errado.
    expect(
      () => extractPdfText(
        onePage(
          'BT /F1 12 Tf 72 720 Td (Protegido) Tj ET',
          trailer: '/Root 1 0 R /Encrypt << /Filter /Standard /V 1 /R 2 >>',
        ),
      ),
      throwsA(isA<PdfParseException>()),
    );
  });

  test('arquivo sem estrutura de PDF falha em vez de devolver vazio', () {
    expect(
      () => extractPdfText(Uint8List.fromList(utf8.encode('nao sou um pdf'))),
      throwsA(isA<PdfParseException>()),
    );
  });
}
