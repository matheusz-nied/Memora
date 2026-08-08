import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memora/core/backend/local/local_pdf_text_gateway.dart';
import 'package:memora/core/backend/models/backend_exception.dart';
import 'package:memora/core/constants/app_constants.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  // Roda o parse no mesmo isolate: `compute` em flutter_test é lento e
  // instável, e o que importa aqui é a regra, não onde ela executa.
  final gateway = LocalPdfTextGateway(
    parse: (bytes) async => parsePdfBytes(bytes),
  );

  /// Gera um PDF de verdade — o mesmo pacote que lê também escreve, então o
  /// teste exercita o parser contra um arquivo real em vez de um mock.
  Future<Uint8List> buildPdf({required List<String> pagesText}) async {
    final document = PdfDocument();
    final font = PdfStandardFont(PdfFontFamily.helvetica, 12);

    for (final text in pagesText) {
      final page = document.pages.add();
      if (text.isNotEmpty) {
        page.graphics.drawString(text, font);
      }
    }

    final bytes = Uint8List.fromList(await document.save());
    document.dispose();
    return bytes;
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
