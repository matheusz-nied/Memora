class AppConstants {
  const AppConstants._();

  static const String appName = 'Memora';

  static const int kMaxTextInput = 4000;
  static const int kMaxPdfSizeMb = 5;
  static const int kMaxPdfPages = 10;
  static const List<int> kCardQuantityOptions = [5, 10, 15];
  static const int kMaxCardFront = 300;
  static const int kMaxCardBack = 600;
  static const int kMaxDeckTitle = 60;
  static const int kMaxDeckDescription = 200;
  static const int kMaxChatMessages = 40;
  static const int kLocalPageSize = 30;
  static const double kContentMaxWidth = 640.0;
  static const String kOnboardingKey = 'onboarding_complete';
}
