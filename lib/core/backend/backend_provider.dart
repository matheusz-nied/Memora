import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_client.dart';
import 'disabled_backend_client.dart';
import 'models/backend_exception.dart';
import 'supabase/supabase_backend_client.dart';

final backendClientProvider = Provider<BackendClient>((ref) {
  try {
    return SupabaseBackendClient.instance();
  } on BackendException {
    return const DisabledBackendClient();
  }
});
