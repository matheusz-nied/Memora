import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend_client.dart';
import '../contracts/ai_gateway.dart';
import '../contracts/auth_gateway.dart';
import '../contracts/remote_database_gateway.dart';
import '../contracts/storage_gateway.dart';
import '../models/backend_exception.dart';
import 'supabase_ai_gateway.dart';
import 'supabase_auth_gateway.dart';
import 'supabase_remote_database_gateway.dart';
import 'supabase_storage_gateway.dart';

class SupabaseBackendClient implements BackendClient {
  SupabaseBackendClient._(SupabaseClient client)
    : auth = SupabaseAuthGateway(client),
      database = SupabaseRemoteDatabaseGateway(client),
      storage = SupabaseStorageGateway(client),
      ai = SupabaseAiGateway(client);

  static const String _envSupabaseUrl = 'SUPABASE_URL';
  static const String _envSupabaseAnonKey = 'SUPABASE_ANON_KEY';

  static bool _initialized = false;

  static Future<void> initializeFromEnvironment() async {
    if (!dotenv.isInitialized) {
      await dotenv.load(fileName: '.env', isOptional: true);
    }

    final url = _normalizeSupabaseUrl(dotenv.maybeGet(_envSupabaseUrl));
    final anonKey = dotenv.maybeGet(_envSupabaseAnonKey);

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }

  static SupabaseBackendClient instance() {
    if (!_initialized) {
      throw const BackendException(
        'Supabase is not configured. Define SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    return SupabaseBackendClient._(Supabase.instance.client);
  }

  @override
  final AuthGateway auth;

  @override
  final RemoteDatabaseGateway database;

  @override
  final StorageGateway storage;

  @override
  final AiGateway ai;
}

String? _normalizeSupabaseUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return trimmed;
  }

  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$port';
}
