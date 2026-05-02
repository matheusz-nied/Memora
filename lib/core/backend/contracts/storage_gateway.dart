import 'dart:typed_data';

import '../models/storage_upload_result.dart';

abstract interface class StorageGateway {
  Future<StorageUploadResult> uploadPdf({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  });
}
