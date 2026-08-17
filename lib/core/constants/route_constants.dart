class RouteConstants {
  const RouteConstants._();

  static const String kRouteOnboarding = '/onboarding';
  static const String kRouteHome = '/home';
  static const String kRouteApiKey = '/settings/api-key';

  static const String kRouteBackup = '/settings/backup';
  static const String kRouteDeck = '/deck/:deckId';
  static const String kRouteStudy = '/deck/:deckId/study';
  static const String kRouteCardInsight = '/deck/:deckId/card/:cardId/insight';
  static const String kRouteGenerate = '/deck/:deckId/generate';
  static const String kRouteReview = '/deck/:deckId/cards/review';
  static const String kRouteCardImport = '/deck/:deckId/import';
  static const String kRouteChat = '/deck/:deckId/chat';
  static const String kRouteAgentConfig = '/deck/:deckId/agent-config';

  static const String deckIdParam = 'deckId';
  static const String cardIdParam = 'cardId';
  static const String freeStudyParam = 'free';

  static String deckPath(String deckId) => '/deck/$deckId';
  static String studyPath(String deckId, {bool freeStudy = false}) =>
      '/deck/$deckId/study${freeStudy ? '?$freeStudyParam=1' : ''}';
  static String cardInsightPath(String deckId, String cardId) =>
      '/deck/$deckId/card/$cardId/insight';
  static String generatePath(String deckId) => '/deck/$deckId/generate';
  static String reviewPath(String deckId) => '/deck/$deckId/cards/review';
  static String cardImportPath(String deckId) => '/deck/$deckId/import';
  static String chatPath(String deckId) => '/deck/$deckId/chat';
  static String agentConfigPath(String deckId) => '/deck/$deckId/agent-config';
}
