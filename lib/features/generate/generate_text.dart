import '../../core/constants/app_constants.dart';

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
      'Informe um texto com pelo menos ${AppConstants.kMinTextInput} caracteres.';
  static const String textTooLong =
      'O texto deve ter no máximo ${AppConstants.kMaxTextInput} caracteres.';
  static const String invalidQuantity = 'Quantidade inválida.';
  static const String invalidPdf = 'Selecione um arquivo PDF válido.';
  static const String pdfTooLarge =
      'O PDF deve ter no máximo ${AppConstants.kMaxPdfSizeMb} MB.';
  static const String pdfTooManyPages =
      'O PDF deve ter no máximo ${AppConstants.kMaxPdfPages} páginas.';
  static const String pdfNoText =
      'Este PDF parece ser escaneado ou não tem texto selecionável. '
      'Envie outro arquivo ou cole o conteúdo como texto.';
  static const String noPdf = 'Selecione um PDF para continuar.';
  static const String noSession = 'Sessão expirada. Entre novamente.';
  static const String extractingPdf = 'Lendo o PDF...';
  static const String aiTimeout =
      'A IA demorou demais para responder. Tente novamente.';
  static const String quotaExceeded =
      'Seus créditos de IA deste mês acabaram. '
      'Eles são renovados no início do próximo ciclo.';
  static const String rateLimited =
      'Muitas gerações seguidas. Aguarde alguns segundos e tente de novo.';
  static const String partialTitle = 'Geração incompleta';
  static const String usePartialCards = 'Usar os cards gerados';
  static const String discardPartialCards = 'Descartar';

  static String insufficientCredits({
    required int needed,
    required int available,
  }) {
    return 'Esta geração precisa de $needed créditos de IA e você tem '
        '$available. Gere menos cards ou aguarde a renovação do ciclo.';
  }

  static String generatingBatch({
    required int batch,
    required int batches,
    required int cards,
    required int requested,
  }) {
    return 'Gerando lote $batch de $batches — $cards de $requested cards';
  }

  static String partialMessage({required int cards, required String reason}) {
    return 'Geramos $cards cards antes de uma falha: $reason';
  }
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
