import 'dart:typed_data';

import '../models/pdf_extraction_result.dart';

/// Transforma os bytes de um PDF no texto que vai virar cards.
///
/// Contrato próprio, separado do [AiGateway], porque **não é uma operação de
/// IA**: é leitura de arquivo. Separar permite que cada backend resolva do seu
/// jeito — no servidor, subindo para um bucket e lendo numa Edge Function; no
/// aparelho, extraindo direto dos bytes — sem que o `GenerateRepository`
/// precise saber qual dos dois está ativo.
abstract interface class PdfTextGateway {
  /// Extrai o texto de [bytes].
  ///
  /// Recebe os bytes, e não um caminho, porque caminho de storage é detalhe de
  /// uma implementação só. Quem sobe o arquivo, quando isso é necessário, é o
  /// próprio adaptador.
  Future<PdfExtractionResult> extractText({
    required String fileName,
    required Uint8List bytes,
  });
}
