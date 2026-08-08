import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../constants/app_constants.dart';
import '../contracts/pdf_text_gateway.dart';
import '../models/backend_exception.dart';
import '../models/pdf_extraction_result.dart';

/// Texto cru saído do parser, antes de qualquer regra de negócio.
@immutable
class PdfRawText {
  const PdfRawText({required this.text, required this.pages});

  final String text;
  final int pages;
}

/// Assinatura de quem executa o parse. Existe para o teste rodar o mesmo
/// código sem isolate — `compute` em `flutter_test` é lento e instável.
typedef PdfParser = Future<PdfRawText> Function(Uint8List bytes);

/// Extrai o texto do PDF no próprio aparelho, sem servidor nem storage.
///
/// Os limites são os mesmos da Edge Function equivalente
/// (`supabase/functions/extract-pdf-text/index.ts`), para o usuário receber a
/// mesma resposta nos dois modos.
class LocalPdfTextGateway implements PdfTextGateway {
  const LocalPdfTextGateway({PdfParser parse = _parseInIsolate})
    : _parse = parse;

  /// Teto do que volta para quem chama. Um PDF de 100 páginas rende ~250 mil
  /// caracteres; acima disso o texto pesa mais do que rende em cards.
  static const int maxReturnedChars = 500000;

  final PdfParser _parse;

  @override
  Future<PdfExtractionResult> extractText({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (bytes.length > AppConstants.kMaxPdfSizeMb * 1024 * 1024) {
      throw BackendException(
        'O PDF deve ter no máximo ${AppConstants.kMaxPdfSizeMb} MB.',
        code: 'pdf_too_large',
      );
    }

    final PdfRawText raw;
    try {
      raw = await _parse(bytes);
    } catch (error) {
      debugPrint('local pdf parse failed: $error');
      throw const BackendException(
        'Não foi possível ler este PDF. Verifique se o arquivo não está '
        'corrompido ou protegido por senha.',
        code: 'pdf_parse_failed',
      );
    }

    if (raw.pages > AppConstants.kMaxPdfPages) {
      throw BackendException(
        'O PDF deve ter no máximo ${AppConstants.kMaxPdfPages} páginas.',
        code: 'pdf_too_many_pages',
      );
    }

    final text = raw.text.trim();

    // Não há OCR: PDF escaneado devolve string vazia. A mensagem precisa dizer
    // isso, porque "texto insuficiente" leva o usuário a procurar um arquivo
    // maior — que também não vai funcionar. Espelha GenerateText.pdfNoText.
    if (text.length < AppConstants.kMinTextInput) {
      throw const BackendException(
        'Este PDF parece ser escaneado ou não tem texto selecionável. '
        'Envie outro arquivo ou cole o conteúdo como texto.',
        code: 'pdf_no_text',
      );
    }

    return PdfExtractionResult(
      text: text.length <= maxReturnedChars
          ? text
          : text.substring(0, maxReturnedChars),
      pages: raw.pages,
    );
  }
}

Future<PdfRawText> _parseInIsolate(Uint8List bytes) {
  // Parsear PDF é trabalho de CPU: no thread da UI, um documento grande
  // congelaria a tela por segundos.
  return compute(parsePdfBytes, bytes);
}

/// Lê o documento. Precisa ser top-level para poder rodar num isolate.
///
/// Devolve texto vazio quando o PDF passa do limite de páginas: extrair tudo
/// para depois descartar seria desperdício, e quem decide é [LocalPdfTextGateway].
PdfRawText parsePdfBytes(Uint8List bytes) {
  final document = PdfDocument(inputBytes: bytes);
  try {
    final pages = document.pages.count;
    if (pages > AppConstants.kMaxPdfPages) {
      return PdfRawText(text: '', pages: pages);
    }

    return PdfRawText(
      text: PdfTextExtractor(document).extractText(),
      pages: pages,
    );
  } finally {
    document.dispose();
  }
}
