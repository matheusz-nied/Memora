import '../../core/backend/models/backend_exception.dart';
import '../../core/backend/models/generated_card.dart';

enum GeneratePhase {
  /// Lendo o PDF antes de qualquer chamada à IA.
  extracting,

  /// Gerando cards, lote a lote.
  generating,
}

/// Andamento de uma geração para a tela mostrar sem adivinhar.
class GenerateProgress {
  const GenerateProgress({
    required this.phase,
    required this.batchesDone,
    required this.batchesTotal,
    required this.cardsDone,
    required this.cardsRequested,
  });

  final GeneratePhase phase;
  final int batchesDone;
  final int batchesTotal;
  final int cardsDone;
  final int cardsRequested;

  /// `null` enquanto não há lote para medir — a barra fica indeterminada.
  double? get fraction {
    if (phase == GeneratePhase.extracting || batchesTotal == 0) {
      return null;
    }
    return batchesDone / batchesTotal;
  }
}

/// Resultado de uma geração, que pode ter parado no meio.
///
/// Lotes já concluídos são cards reais: descartá-los porque o último falhou
/// gastaria a quota do usuário duas vezes pelo mesmo material.
class GenerationResult {
  const GenerationResult({required this.cards, this.error});

  final List<GeneratedCard> cards;
  final BackendException? error;

  bool get isComplete => error == null;

  bool get isPartial => error != null && cards.isNotEmpty;

  bool get isFailure => error != null && cards.isEmpty;
}
