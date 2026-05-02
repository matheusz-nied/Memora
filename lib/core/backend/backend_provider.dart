import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_client.dart';
import 'supabase/supabase_backend_client.dart';

final backendClientProvider = Provider<BackendClient>((ref) {
  return SupabaseBackendClient.instance();
});
