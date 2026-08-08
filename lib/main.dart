import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/app.dart';
import 'package:memora/core/backend/local/local_backend_client.dart';
import 'package:memora/core/backend/supabase/supabase_backend_client.dart';
import 'package:memora/core/config/app_mode.dart';
import 'package:memora/core/storage/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // As condições são `const`: o bootstrap do modo que não foi compilado sai
  // do binário junto com o adaptador dele.
  if (kIsCloudMode) {
    await SupabaseBackendClient.initializeFromEnvironment();
  } else {
    await LocalBackendClient.initialize(sharedPreferences);
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MemoraApp(),
    ),
  );
}
