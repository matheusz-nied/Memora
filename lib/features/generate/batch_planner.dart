import '../../core/constants/app_constants.dart';

/// Divide um pedido de cards em lotes que cabem numa chamada à IA.
///
/// Os lotes ficam do mesmo tamanho (50 vira 13/13/12/12, não 15/15/15/5):
/// um lote final minúsculo custa a mesma unidade de quota que um cheio.
List<int> computeBatchSizes(
  int quantity, {
  int maxBatchSize = AppConstants.kMaxCardsPerBatch,
}) {
  if (quantity <= 0) {
    return const [];
  }
  if (quantity <= maxBatchSize) {
    return [quantity];
  }

  final batches = (quantity / maxBatchSize).ceil();
  final base = quantity ~/ batches;
  final remainder = quantity % batches;

  return List<int>.generate(
    batches,
    (index) => index < remainder ? base + 1 : base,
  );
}

/// Fatia o material em trechos que cabem no prompt de um lote.
///
/// Corta em fronteira de parágrafo quando possível, senão em fim de frase:
/// um corte no meio de uma frase gera card sobre uma ideia truncada.
List<String> chunkText(
  String text, {
  int targetChars = AppConstants.kChunkTargetChars,
  int minChars = AppConstants.kChunkMinChars,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return const [];
  }
  if (trimmed.length <= targetChars) {
    return [trimmed];
  }

  final chunks = <String>[];
  var start = 0;

  while (start < trimmed.length) {
    final remaining = trimmed.length - start;
    if (remaining <= targetChars) {
      chunks.add(trimmed.substring(start).trim());
      break;
    }

    final end = _breakPoint(trimmed, start, start + targetChars);
    chunks.add(trimmed.substring(start, end).trim());
    start = end;
  }

  final result = chunks.where((chunk) => chunk.isNotEmpty).toList();

  // Uma sobra curta demais não rende cards sozinha; volta para o trecho
  // anterior, que ganha contexto em vez de perder.
  if (result.length > 1 && result.last.length < minChars) {
    final tail = result.removeLast();
    result[result.length - 1] = '${result.last}\n\n$tail';
  }

  return result;
}

/// Procura de trás para frente a melhor fronteira de corte antes de [limit].
int _breakPoint(String text, int start, int limit) {
  final window = text.substring(start, limit);

  // Só aceita fronteira na metade final da janela: uma quebra logo no início
  // produziria um trecho minúsculo e desperdiçaria o lote.
  final floor = window.length ~/ 2;

  final paragraph = window.lastIndexOf('\n\n');
  if (paragraph > floor) {
    return start + paragraph + 2;
  }

  for (final terminator in const ['. ', '.\n', '? ', '! ']) {
    final sentence = window.lastIndexOf(terminator);
    if (sentence > floor) {
      return start + sentence + terminator.length;
    }
  }

  final space = window.lastIndexOf(' ');
  if (space > floor) {
    return start + space + 1;
  }

  return limit;
}

/// Escolhe o trecho que alimenta cada lote.
///
/// Com material sobrando, os lotes se espalham pelo documento em vez de
/// cobrirem só o começo. Com menos trechos que lotes, eles se revezam — e a
/// lista de frentes já geradas é o que evita repetição no mesmo trecho.
int chunkIndexForBatch({
  required int batchIndex,
  required int batchCount,
  required int chunkCount,
}) {
  if (chunkCount <= 1 || batchCount <= 0) {
    return 0;
  }
  if (chunkCount >= batchCount) {
    return (batchIndex * chunkCount) ~/ batchCount;
  }
  return batchIndex % chunkCount;
}
