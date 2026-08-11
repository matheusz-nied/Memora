import '../../core/constants/app_constants.dart';

class CardText {
  const CardText._();

  static const String title = 'Cards';
  static const String newCard = 'Novo card';
  static const String editCard = 'Editar card';
  static const String front = 'Frente';
  static const String back = 'Verso';
  static const String frontHint = 'O que você quer memorizar?';
  static const String backHint = 'A resposta é...';
  static const String save = 'Salvar';
  static const String cancel = 'Cancelar';
  static const String edit = 'Editar';
  static const String delete = 'Excluir';
  static const String emptyTitle = 'Nenhum card ainda';
  static const String emptyMessage =
      'Adicione cards manualmente, importe um JSON ou gere por IA.';
  static const String confirmDeleteCardTitle = 'Excluir card?';
  static const String confirmDeleteCardMessage =
      'Este card será removido deste deck.';
  static const String frontRequired = 'Informe a frente do card.';
  static const String backRequired = 'Informe o verso do card.';
  static const String frontTooLong = 'Use até 300 caracteres.';
  static const String backTooLong = 'Use até 600 caracteres.';
  static const String loadError = 'Não foi possível carregar os cards.';
  static const String addCards = 'Adicionar cards';
  static const String importJson = 'Importar JSON';
  static const String importJsonTitle = 'Importar cards por JSON';
  static const String importJsonSubtitle =
      'Selecione um arquivo JSON com perguntas e respostas para revisar antes de salvar.';
  static const String importJsonFormatTitle = 'Formato aceito';
  static const String importJsonFormatDescription =
      'Use version 1 e uma lista de cards com frente e verso. Cards inválidos ou repetidos serão ignorados.';
  static const String importJsonExample = '''{
  "version": 1,
  "cards": [
    {"front": "Pergunta", "back": "Resposta"}
  ]
}''';
  static const String selectJson = 'Selecionar arquivo JSON';
  static const String importingJson = 'Importando cards...';
  static const String importJsonUnreadable =
      'Não foi possível ler o arquivo selecionado.';
  static const String importJsonInvalid =
      'O arquivo não está no formato de importação do Memora.';
  static const String importJsonUnsupportedVersion =
      'Esta versão do arquivo ainda não é suportada.';
  static const String importJsonTooLarge =
      'O arquivo deve ter no máximo ${AppConstants.kMaxCardImportSizeMb} MB.';
  static const String importJsonTooManyCards =
      'O arquivo deve ter no máximo ${AppConstants.kMaxCardsPerImport} cards.';
  static const String importJsonNoCards =
      'Não encontramos cards válidos para importar.';
  static String importJsonLimits({
    required int maxCards,
    required int maxSizeMb,
  }) => 'Máximo de $maxCards cards e $maxSizeMb MB por arquivo.';
  static String importIgnoredSummary({
    required int invalid,
    required int duplicates,
  }) {
    final parts = <String>[];
    if (invalid > 0) parts.add('$invalid inválido(s)');
    if (duplicates > 0) parts.add('$duplicates duplicado(s)');
    return parts.isEmpty
        ? ''
        : '${parts.join(' e ')} ${parts.length == 1 ? 'foi ignorado' : 'foram ignorados'}.';
  }
}
