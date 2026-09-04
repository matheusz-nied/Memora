import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import '../../core/identity/device_user_id.dart';
import '../cards/card_draft.dart';
import '../cards/card_import_repository.dart';
import '../cards/card_text.dart';
import 'deck_text.dart';

final deckImportRepositoryProvider = Provider<DeckImportRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DeckImportRepository(
    database: database,
    userId: ref.watch(deviceUserIdProvider),
    cardImportRepository: CardImportRepository(database: database),
  );
});

class DeckImportFile {
  const DeckImportFile({required this.name, required this.bytes});

  final String name;
  final Uint8List? bytes;
}

class ImportedDeck {
  const ImportedDeck({
    required this.fileName,
    required this.deckTitle,
    required this.cards,
    required this.ignoredCards,
  });

  final String fileName;
  final String deckTitle;
  final int cards;
  final int ignoredCards;
}

class DeckImportFailure {
  const DeckImportFailure({required this.fileName, required this.message});

  final String fileName;
  final String message;
}

class DeckImportSummary {
  const DeckImportSummary({required this.imported, required this.failures});

  final List<ImportedDeck> imported;
  final List<DeckImportFailure> failures;

  int get totalCards => imported.fold(0, (total, item) => total + item.cards);
  int get ignoredCards =>
      imported.fold(0, (total, item) => total + item.ignoredCards);
}

/// Cria um deck por JSON e mantém cada arquivo atômico.
class DeckImportRepository {
  DeckImportRepository({
    required AppDatabase database,
    required String userId,
    required CardImportRepository cardImportRepository,
    Uuid uuid = const Uuid(),
  }) : _database = database,
       _userId = userId,
       _cardImportRepository = cardImportRepository,
       _uuid = uuid;

  final AppDatabase _database;
  final String _userId;
  final CardImportRepository _cardImportRepository;
  final Uuid _uuid;

  Future<DeckImportSummary> importFiles(List<DeckImportFile> files) async {
    final currentDecks = await _database.decksDao.getAllDecks(userId: _userId);
    final usedTitles = {
      for (final deck in currentDecks) _normalizeTitle(deck.title),
    };
    final imported = <ImportedDeck>[];
    final failures = <DeckImportFailure>[];

    for (final file in files) {
      try {
        final bytes = file.bytes;
        if (bytes == null) {
          throw const CardImportException(CardText.importJsonUnreadable);
        }
        final parsed = _cardImportRepository.parseJson(bytes: bytes);
        final title = _uniqueTitle(file.name, usedTitles);
        await _insertDeck(title: title, cards: parsed.cards);
        usedTitles.add(_normalizeTitle(title));
        imported.add(
          ImportedDeck(
            fileName: file.name,
            deckTitle: title,
            cards: parsed.cards.length,
            ignoredCards: parsed.invalidCards + parsed.duplicateCards,
          ),
        );
      } on CardImportException catch (error) {
        failures.add(
          DeckImportFailure(fileName: file.name, message: error.message),
        );
      } catch (_) {
        failures.add(
          DeckImportFailure(
            fileName: file.name,
            message: DeckText.importDecksFileFailed,
          ),
        );
      }
    }

    return DeckImportSummary(imported: imported, failures: failures);
  }

  Future<void> _insertDeck({
    required String title,
    required List<CardDraft> cards,
  }) async {
    final deckId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.transaction(() async {
      await _database.decksDao.upsertDeck(
        DecksTableCompanion.insert(
          id: deckId,
          userId: _userId,
          title: title,
          createdAt: now,
          updatedAt: now,
        ),
      );
      for (var index = 0; index < cards.length; index++) {
        final card = cards[index];
        final timestamp = now + index;
        await _database.cardsDao.upsertCard(
          CardsTableCompanion.insert(
            id: _uuid.v4(),
            deckId: deckId,
            front: card.front.trim(),
            back: card.back.trim(),
            dueDate: now,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        );
      }
    });
  }

  String _uniqueTitle(String fileName, Set<String> usedTitles) {
    final withoutExtension = fileName.replaceFirst(
      RegExp(r'\.json$', caseSensitive: false),
      '',
    );
    final rawBase = withoutExtension.trim().isEmpty
        ? DeckText.importedDeckFallbackName
        : withoutExtension.trim();
    final base = _truncate(rawBase, AppConstants.kMaxDeckTitle);
    if (!usedTitles.contains(_normalizeTitle(base))) {
      return base;
    }

    var suffixNumber = 2;
    while (true) {
      final suffix = DeckText.importedDeckDuplicateSuffix(suffixNumber);
      final candidate =
          '${_truncate(base, AppConstants.kMaxDeckTitle - suffix.length)}$suffix';
      if (!usedTitles.contains(_normalizeTitle(candidate))) {
        return candidate;
      }
      suffixNumber += 1;
    }
  }

  String _truncate(String value, int maxLength) =>
      value.length <= maxLength ? value : value.substring(0, maxLength).trim();

  String _normalizeTitle(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
