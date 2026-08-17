import 'dart:typed_data';

import '../models/pdf_extraction_result.dart';

/// Transforma os bytes de um PDF no texto que vai virar cards.
///
/// Contrato próprio, separado do [AiGateway], porque **não é uma operação de
/// IA**: é leitura de arquivo. Separar deixa trocar o extrator sem que o
/// `GenerateRepository` fique sabendo.
abstract interface class PdfTextGateway {
  /// Extrai o texto de [bytes].
  ///
  /// Recebe os bytes, e não um caminho, porque caminho de arquivo é detalhe de
  /// quem escolheu o PDF, não de quem o lê.
  Future<PdfExtractionResult> extractText({
    required String fileName,
    required Uint8List bytes,
  });
}
