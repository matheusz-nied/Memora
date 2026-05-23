class RouteConstants {
  const RouteConstants._();

  static const String kRouteOnboarding = '/onboarding';
  static const String kRouteLogin = '/login';
  static const String kRouteRegister = '/register';
  static const String kRouteForgotPass = '/forgot-password';
  static const String kRouteHome = '/home';
  static const String kRouteProfile = '/profile';
  static const String kRouteDeck = '/deck/:deckId';
  static const String kRouteStudy = '/deck/:deckId/study';
  static const String kRouteCardInsight = '/deck/:deckId/card/:cardId/insight';
  static const String kRouteGenerate = '/deck/:deckId/generate';
  static const String kRouteReview = '/deck/:deckId/generate/review';
  static const String kRouteChat = '/deck/:deckId/chat';
  static const String kRouteAgentConfig = '/deck/:deckId/agent-config';

  static const String deckIdParam = 'deckId';
  static const String cardIdParam = 'cardId';

  static String deckPath(String deckId) => '/deck/$deckId';
  static String studyPath(String deckId) => '/deck/$deckId/study';
  static String cardInsightPath(String deckId, String cardId) =>
      '/deck/$deckId/card/$cardId/insight';
  static String generatePath(String deckId) => '/deck/$deckId/generate';
  static String reviewPath(String deckId) => '/deck/$deckId/generate/review';
  static String chatPath(String deckId) => '/deck/$deckId/chat';
  static String agentConfigPath(String deckId) => '/deck/$deckId/agent-config';
}
