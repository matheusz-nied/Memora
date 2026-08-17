import 'dart:convert';

import '../../core/database/app_database.dart';

/// Marca o arquivo como sendo do Memora.
///
/// Sem isto, escolher o JSON errado no seletor de arquivos daria um erro de
/// campo faltando em vez de "este arquivo não é um backup do Memora".
const String kBackupApp = 'memora';

/// Falha de leitura do arquivo, já com mensagem para a tela.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Conteúdo de um arquivo de backup.
class BackupData {
  const BackupData({
    required this.schema,
    required this.exportedAt,
    required this.decks,
    required this.cards,
    required this.reviews,
  });

  final int schema;
  final DateTime exportedAt;
  final List<LocalDeck> decks;
  final List<LocalCard> cards;
  final List<LocalReview> reviews;
}

/// Serializa tudo num JSON versionado.
///
/// As listas são planas, e não aninhadas, porque `reviews` referencia card e
/// deck ao mesmo tempo: aninhar obrigaria a escolher um dono e reconstruir o
/// outro vínculo na leitura.
String encodeBackup({
  required List<LocalDeck> decks,
  required List<LocalCard> cards,
  required List<LocalReview> reviews,
  required DateTime exportedAt,
  int schema = AppDatabase.latestSchemaVersion,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'app': kBackupApp,
    'schema': schema,
    'exportedAt': exportedAt.toIso8601String(),
    'decks': decks.map((deck) => deck.toJson()).toList(),
    'cards': cards.map((card) => card.toJson()).toList(),
    'reviews': reviews.map((review) => review.toJson()).toList(),
  });
}

/// Lê e valida um arquivo de backup.
///
/// Recusa arquivo de uma versão futura em vez de tentar adivinhar: um schema
/// mais novo pode ter colunas que este build não conhece, e importar pela
/// metade é pior do que não importar.
BackupData decodeBackup(String source) {
  final Object? parsed;
  try {
    parsed = jsonDecode(source);
  } on FormatException {
    throw const BackupException(
      'Arquivo inválido: não é um JSON que o Memora consiga ler.',
    );
  }

  if (parsed is! Map<String, dynamic>) {
    throw const BackupException('Arquivo inválido: conteúdo inesperado.');
  }

  if (parsed['app'] != kBackupApp) {
    throw const BackupException(
      'Este arquivo não parece ser um backup do Memora.',
    );
  }

  final schema = parsed['schema'];
  if (schema is! int) {
    throw const BackupException('Arquivo inválido: versão não identificada.');
  }
  if (schema > AppDatabase.latestSchemaVersion) {
    throw BackupException(
      'Este backup foi feito numa versão mais nova do app (formato $schema). '
      'Atualize o Memora para importá-lo.',
    );
  }

  return BackupData(
    schema: schema,
    exportedAt:
        DateTime.tryParse(parsed['exportedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    decks: _mapList(parsed['decks'], LocalDeck.fromJson, 'decks'),
    cards: _mapList(
      parsed['cards'],
      (map) => LocalCard.fromJson(_normalizeCardMap(map)),
      'cards',
    ),
    reviews: _mapList(
      parsed['reviews'],
      (map) => LocalReview.fromJson(_normalizeReviewMap(map)),
      'reviews',
    ),
  );
}

Map<String, dynamic> _normalizeCardMap(Map<String, dynamic> source) {
  return {
    ...source,
    'easeFactor': source['easeFactor'] ?? 2.5,
    'intervalDays': source['intervalDays'] ?? 1,
    'repetitions': source['repetitions'] ?? 0,
    'fsrsState': source['fsrsState'] ?? 1,
    'fsrsStep': source['fsrsStep'],
    'stability': source['stability'],
    'difficulty': source['difficulty'],
    'lastReview': source['lastReview'],
    'insight': source['insight'],
    'deletedAt': source['deletedAt'],
  };
}

Map<String, dynamic> _normalizeReviewMap(Map<String, dynamic> source) {
  return {
    ...source,
    'easeBefore': source['easeBefore'] ?? 2.5,
    'easeAfter': source['easeAfter'] ?? 2.5,
    'intervalBefore': source['intervalBefore'] ?? 1,
    'intervalAfter': source['intervalAfter'] ?? 1,
    'reviewKind': source['reviewKind'] ?? 0,
  };
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic>) fromJson,
  String field,
) {
  if (value == null) {
    return const [];
  }
  if (value is! List) {
    throw BackupException('Arquivo inválido: "$field" está corrompido.');
  }

  try {
    return value
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  } catch (_) {
    throw BackupException('Arquivo inválido: "$field" está corrompido.');
  }
}
