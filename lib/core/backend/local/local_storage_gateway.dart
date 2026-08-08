import 'dart:typed_data';

import '../contracts/storage_gateway.dart';
import '../models/backend_exception.dart';
import '../models/storage_upload_result.dart';

/// Não há bucket neste modo.
///
/// O único uso de storage é subir o PDF para a Edge Function extrair o texto,
/// e essa opção não aparece na tela local — então isto nunca deveria ser
/// chamado.
class LocalStorageGateway implements StorageGateway {
  const LocalStorageGateway();

  @override
  Future<StorageUploadResult> uploadPdf({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) {
    throw const BackendException(
      'Envio de arquivos não está disponível neste modo.',
      code: 'storage_unsupported',
    );
  }
}
