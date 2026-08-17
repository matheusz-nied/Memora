import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/local/local_pdf_text_gateway.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/constants/app_constants.dart';
import 'package:pdf/pdf.dart';

void main() {
  // Roda o parse no mesmo isolate: `compute` em flutter_test é lento e
  // instável, e o que importa aqui é a regra, não onde ela executa.
  final gateway = LocalPdfTextGateway(
    parse: (bytes) async => parsePdfBytes(bytes),
  );

  /// Gera um PDF de verdade.
  ///
  /// Quem escreve é o pacote `pdf` e quem lê é o extrator do app — são códigos
  /// independentes, então o teste vale como prova de que a leitura funciona
  /// contra um arquivo que não foi feito sob medida para ela. O `pdf` grava na
  /// versão 1.5, que usa xref stream e object stream: o caminho moderno é o
  /// exercitado aqui.
  Future<Uint8List> buildPdf({required List<String> pagesText}) async {
    final document = PdfDocument();
    final font = PdfFont.helvetica(document);

    for (final text in pagesText) {
      final page = PdfPage(document, pageFormat: PdfPageFormat.a4);
      // Página sem `drawString` sai sem conteúdo nenhum — que é justamente o
      // que um PDF escaneado parece para quem procura texto.
      if (text.isNotEmpty) {
        page.getGraphics().drawString(font, 12, text, 50, 700);
      }
    }

    return document.save();
  }

  test('extrai o texto e conta as páginas', () async {
    final bytes = await buildPdf(
      pagesText: [
        'Mitocondria e a organela responsavel pela respiracao celular.',
        'Ribossomos produzem proteinas a partir do RNA mensageiro.',
      ],
    );

    final result = await gateway.extractText(
      fileName: 'biologia.pdf',
      bytes: bytes,
    );

    expect(result.pages, 2);
    expect(result.text, contains('Mitocondria'));
    expect(result.text, contains('Ribossomos'));
  });

  test('preserva as palavras separadas dentro da frase', () async {
    const frase =
        'A membrana plasmatica regula o transporte de substancias na celula.';
    final bytes = await buildPdf(pagesText: const [frase]);

    final result = await gateway.extractText(
      fileName: 'citologia.pdf',
      bytes: bytes,
    );

    // O risco real do extrator geométrico é grudar palavra ("amembrana") ou
    // partir palavra ("mem brana"). A frase inteira cobre os dois casos.
    expect(result.text, contains(frase));
  });

  test('lê acentuação sem trocar caractere', () async {
    final bytes = await buildPdf(
      pagesText: const [
        'Ação, célula e função não podem sair corrompidas na leitura.',
      ],
    );

    final result = await gateway.extractText(
      fileName: 'acentos.pdf',
      bytes: bytes,
    );

    expect(result.text, contains('Ação'));
    expect(result.text, contains('célula'));
    expect(result.text, contains('função'));
    expect(result.text, contains('não'));
  });

  test('PDF sem texto selecionável avisa que pode ser escaneado', () async {
    // Página em branco é o que um PDF escaneado devolve: não há OCR aqui.
    final bytes = await buildPdf(pagesText: const ['', '']);

    await expectLater(
      gateway.extractText(fileName: 'digitalizado.pdf', bytes: bytes),
      throwsA(
        isA<BackendException>()
            .having((error) => error.code, 'code', 'pdf_no_text')
            .having((error) => error.message, 'message', contains('escaneado')),
      ),
    );
  });

  test('recusa PDF acima do limite de páginas', () async {
    final bytes = await buildPdf(
      pagesText: List.filled(AppConstants.kMaxPdfPages + 1, 'pagina'),
    );

    await expectLater(
      gateway.extractText(fileName: 'longo.pdf', bytes: bytes),
      throwsA(
        isA<BackendException>().having(
          (error) => error.code,
          'code',
          'pdf_too_many_pages',
        ),
      ),
    );
  });

  test(
    'recusa arquivo acima do limite de tamanho sem tentar parsear',
    () async {
      var parsed = false;
      final strict = LocalPdfTextGateway(
        parse: (bytes) async {
          parsed = true;
          return const PdfRawText(text: '', pages: 0);
        },
      );

      final tooBig = Uint8List(AppConstants.kMaxPdfSizeMb * 1024 * 1024 + 1);

      await expectLater(
        strict.extractText(fileName: 'grande.pdf', bytes: tooBig),
        throwsA(
          isA<BackendException>().having(
            (error) => error.code,
            'code',
            'pdf_too_large',
          ),
        ),
      );
      expect(parsed, isFalse);
    },
  );

  test('arquivo corrompido vira um erro explicável', () async {
    await expectLater(
      gateway.extractText(
        fileName: 'quebrado.pdf',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      ),
      throwsA(
        isA<BackendException>()
            .having((error) => error.code, 'code', 'pdf_parse_failed')
            .having(
              (error) => error.message,
              'message',
              contains('corrompido'),
            ),
      ),
    );
  });
}
