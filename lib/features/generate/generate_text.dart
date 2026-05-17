class GenerateText {
  const GenerateText._();

  static const String title = 'Gerar cards';
  static const String importTitle = 'Importe seu conteúdo';
  static const String importSubtitle =
      'Cole um texto ou envie um PDF para a IA sugerir flashcards.';
  static const String textMode = 'Texto';
  static const String pdfMode = 'PDF';
  static const String sourceTextLabel = 'Texto';
  static const String sourceTextHint =
      'Cole suas anotações, resumo ou trecho de estudo aqui.';
  static const String quantity = 'Quantidade';
  static const String generate = 'Gerar cards';
  static const String generating = 'Gerando cards...';
  static const String selectPdf = 'Selecionar PDF';
  static const String selectedPdf = 'PDF selecionado';
  static const String changePdf = 'Trocar PDF';
  static const String offline =
      'A geração com IA requer internet. Conecte-se para gerar cards.';
  static const String textRequired = 'Informe um texto para gerar cards.';
  static const String textTooShort =
      'Informe um texto com pelo menos 100 caracteres.';
  static const String textTooLong =
      'O texto deve ter no máximo 4000 caracteres.';
  static const String invalidQuantity = 'Quantidade inválida.';
  static const String invalidPdf = 'Selecione um arquivo PDF válido.';
  static const String pdfTooLarge = 'O PDF deve ter no máximo 5 MB.';
  static const String noPdf = 'Selecione um PDF para continuar.';
  static const String noSession = 'Sessão expirada. Entre novamente.';
  static const String reviewTitle = 'Revise os cards';
  static const String reviewSubtitle =
      'Edite ou remova sugestões antes de salvar.';
  static const String saveCards = 'Salvar cards';
  static const String discardReviewTitle = 'Sair sem salvar?';
  static const String discardReviewMessage =
      'Os cards gerados ainda não foram salvos. Se você sair agora, essas sugestões serão perdidas.';
  static const String discardReviewCancel = 'Continuar revisando';
  static const String discardReviewConfirm = 'Sair sem salvar';
  static const String emptyReviewTitle = 'Nenhum card para salvar';
  static const String emptyReviewMessage =
      'Volte e gere novas sugestões para continuar.';
  static const String front = 'Frente';
  static const String back = 'Verso';
  static const String remove = 'Remover';
  static const String saved = 'Cards salvos.';
}
