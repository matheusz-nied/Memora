import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sobrescrito no bootstrap, em `main.dart`, com a instância já carregada.
///
/// Mora em `core/` porque não é infraestrutura de nenhuma feature em
/// particular: o onboarding, a identidade local e a chave da DeepSeek leem
/// todos daqui, e `core/` não pode importar `features/`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden.');
});
