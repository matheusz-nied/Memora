import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/preferences_provider.dart';
import '../legal/privacy_consent.dart';

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(
      OnboardingCompletedNotifier.new,
    );

class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    final preferences = ref.watch(sharedPreferencesProvider);
    return preferences.getBool(AppConstants.kOnboardingKey) ?? false;
  }

  Future<void> complete() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setBool(AppConstants.kOnboardingKey, true);
    state = true;
  }
}

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref);
});

class OnboardingController {
  const OnboardingController(this._ref);

  final Ref _ref;

  Future<void> complete() async {
    // O aceite da política é gravado junto com a conclusão do onboarding: é
    // ali que o texto foi apresentado, e as lojas pedem que o aceite seja
    // registrado, não apenas exibido.
    await _ref.read(privacyAcceptedVersionProvider.notifier).accept();
    await _ref.read(onboardingCompletedProvider.notifier).complete();
  }
}
