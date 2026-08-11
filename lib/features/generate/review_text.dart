import 'card_review_args.dart';

class ReviewText {
  const ReviewText._();

  static const String saveCards = 'Salvar cards';
  static const String saved = 'Cards salvos.';
  static const String discardTitle = 'Sair sem salvar?';
  static const String discardCancel = 'Continuar revisando';
  static const String discardConfirm = 'Sair sem salvar';
  static const String emptyTitle = 'Nenhum card para salvar';
  static const String emptySaveError =
      'Mantenha pelo menos um card para salvar.';
  static const String saveFailed =
      'Não foi possível salvar os cards. Tente novamente.';
  static const String duplicateCards =
      'Há cards duplicados na revisão ou já existentes neste deck.';

  static String title(CardReviewSource source) => switch (source) {
    CardReviewSource.ai => 'Revise os cards gerados',
    CardReviewSource.jsonImport => 'Revise os cards importados',
  };

  static String subtitle(CardReviewSource source) => switch (source) {
    CardReviewSource.ai => 'Edite ou remova as sugestões antes de salvar.',
    CardReviewSource.jsonImport => 'Edite ou remova os cards antes de salvar.',
  };

  static String discardMessage(CardReviewSource source) => switch (source) {
    CardReviewSource.ai =>
      'Os cards gerados ainda não foram salvos. Se você sair agora, essas sugestões serão perdidas.',
    CardReviewSource.jsonImport =>
      'Os cards importados ainda não foram salvos. Se você sair agora, eles serão perdidos.',
  };

  static String emptyMessage(CardReviewSource source) => switch (source) {
    CardReviewSource.ai => 'Volte e gere novas sugestões para continuar.',
    CardReviewSource.jsonImport =>
      'Volte e selecione outro arquivo JSON para continuar.',
  };

  static String emptyAction(CardReviewSource source) => switch (source) {
    CardReviewSource.ai => 'Voltar à geração',
    CardReviewSource.jsonImport => 'Voltar à importação',
  };
}
