import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/app.dart';
import 'package:memora/core/backend/supabase/supabase_backend_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBackendClient.initializeFromEnvironment();

  runApp(const ProviderScope(child: MemoraApp()));
}
