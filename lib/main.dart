import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/app.dart';
import 'package:memora/core/identity/device_user_id.dart';
import 'package:memora/core/storage/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // A identidade do aparelho precisa existir antes da primeira tela: os
  // repositórios leem o id de forma síncrona para montar as queries.
  await DeviceUserId.ensure(sharedPreferences);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MemoraApp(),
    ),
  );
}
