class AppConstants {
  const AppConstants._();

  static const String appName = 'Memora';

  static const int kMinTextInput = 50;
  static const int kMaxTextInput = 4000;
  static const int kMaxPdfSizeMb = 20;
  static const int kMaxPdfPages = 100;
  static const List<int> kCardQuantityOptions = [5, 10, 15, 25, 50];

  /// Cards por chamada à IA. Pedir muito de uma vez degrada a qualidade e
  /// estoura o teto de tokens da resposta, então quantidades maiores viram
  /// vários lotes sequenciais.
  static const int kMaxCardsPerBatch = 15;

  /// Tamanho alvo de cada fatia do material enviada à IA. Fica abaixo de
  /// [kMaxTextInput] para o texto colado caber inteiro em uma fatia.
  static const int kChunkTargetChars = 3500;

  /// Sobra menor que isto é fundida na fatia anterior em vez de virar uma
  /// fatia própria sem contexto suficiente.
  static const int kChunkMinChars = 800;

  /// Frentes já geradas que acompanham o prompt do lote seguinte para evitar
  /// repetição. O teto existe para o prompt não crescer sem limite.
  static const int kMaxAvoidFronts = 60;

  static const int kMaxCardFront = 300;
  static const int kMaxCardBack = 600;
  static const int kMaxCardsPerImport = 500;
  static const int kMaxCardImportSizeMb = 2;
  static const int kMaxDeckTitle = 60;
  static const int kMaxDeckDescription = 200;
  static const int kMaxChatMessages = 40;
  static const int kLocalPageSize = 30;

  /// Cards nunca revisados que entram numa sessão de estudo por dia.
  ///
  /// Evita que um deck recém-gerado com 100 cards apareça como 100 vencidos
  /// de uma vez.
  static const int kNewCardsPerSession = 20;
  static const double kContentMaxWidth = 640.0;
  static const String kOnboardingKey = 'onboarding_complete';
}
