import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../contracts/pdf_text_gateway.dart';
import '../contracts/storage_gateway.dart';
import '../models/backend_exception.dart';
import '../models/pdf_extraction_result.dart';

/// Sobe o PDF ao bucket e pede a extração à Edge Function `extract-pdf-text`.
///
/// Os dois passos vivem juntos porque são um só do ponto de vista de quem
/// chama: o caminho no storage é intermediário e não interessa a mais ninguém.
/// A function apaga o arquivo depois de ler, então o bucket não acumula.
class SupabasePdfTextGateway implements PdfTextGateway {
  const SupabasePdfTextGateway(this._client, this._storage);

  static const String _function = 'extract-pdf-text';

  /// Folga sobre o tempo de execução da function, que faz trabalho de CPU
  /// (`pdf-parse`) e não só espera de rede.
  static const Duration _timeout = Duration(seconds: 150);

  final SupabaseClient _client;
  final StorageGateway _storage;

  @override
  Future<PdfExtractionResult> extractText({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const BackendException('Sessão expirada. Entre novamente.');
    }

    final upload = await _storage.uploadPdf(
      userId: userId,
      fileName: fileName,
      bytes: bytes,
    );

    final FunctionResponse response;
    try {
      response = await _client.functions
          .invoke(_function, body: {'pdfPath': upload.path})
          .timeout(_timeout);
    } on FunctionException catch (error) {
      throw _exceptionFromDetails(error.details);
    } on TimeoutException {
      throw const BackendException(
        'A leitura do PDF demorou demais. Tente novamente.',
        code: BackendException.codeClientTimeout,
      );
    }

    final data = response.data;
    if (data is! Map) {
      throw const BackendException('Invalid pdf extraction response.');
    }
    if (data['error'] != null) {
      throw _exceptionFromDetails(data);
    }

    final text = data['text'];
    if (text is! String) {
      throw const BackendException('Invalid pdf extraction response.');
    }

    return PdfExtractionResult(
      text: text,
      pages: (data['pages'] as num?)?.toInt() ?? 0,
    );
  }

  BackendException _exceptionFromDetails(Object? details) {
    if (details is Map) {
      final message = details['error'];
      if (message != null) {
        return BackendException(
          message.toString(),
          code: details['code'] as String?,
        );
      }
    }

    if (details is String && details.trim().isNotEmpty) {
      return BackendException(details.trim());
    }

    return const BackendException('Não foi possível ler este PDF.');
  }
}
