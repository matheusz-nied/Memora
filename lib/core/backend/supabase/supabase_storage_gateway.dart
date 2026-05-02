import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/backend_constants.dart';
import '../contracts/storage_gateway.dart';
import '../models/storage_upload_result.dart';

class SupabaseStorageGateway implements StorageGateway {
  const SupabaseStorageGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<StorageUploadResult> uploadPdf({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '$userId/$timestamp-$safeFileName';

    await _client.storage
        .from(BackendConstants.kBucketPdfs)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    return StorageUploadResult(
      path: path,
      publicUrl: _client.storage
          .from(BackendConstants.kBucketPdfs)
          .getPublicUrl(path),
    );
  }
}
