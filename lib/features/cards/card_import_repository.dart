import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/database/app_database.dart';
import 'card_draft.dart';
import 'card_text.dart';

final cardImportRepositoryProvider = Provider<CardImportRepository>((ref) {
  return CardImportRepository(database: ref.watch(appDatabaseProvider));
});

class CardImportException implements Exception {
  const CardImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CardImportResult {
  const CardImportResult({
    required this.cards,
    required this.invalidCards,
    required this.duplicateCards,
  });

  final List<CardDraft> cards;
  final int invalidCards;
  final int duplicateCards;
}

/// Converte o formato público de importação em rascunhos seguros para revisão.
class CardImportRepository {
  const CardImportRepository({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<CardImportResult> importJson({
    required String deckId,
    required Uint8List bytes,
  }) async {
    final maxBytes = AppConstants.kMaxCardImportSizeMb * 1024 * 1024;
    if (bytes.length > maxBytes) {
      throw const CardImportException(CardText.importJsonTooLarge);
    }

    final source = _decodeUtf8(bytes);
    final cardsJson = _readCards(source);
    if (cardsJson.length > AppConstants.kMaxCardsPerImport) {
      throw const CardImportException(CardText.importJsonTooManyCards);
    }

    final existingCards = await _database.cardsDao.getCardsForDeck(deckId);
    final seen = {
      for (final card in existingCards) _cardKey(card.front, card.back),
    };
    final cards = <CardDraft>[];
    var invalidCards = 0;
    var duplicateCards = 0;

    for (final value in cardsJson) {
      final draft = _parseDraft(value);
      if (draft == null) {
        invalidCards += 1;
        continue;
      }

      if (!seen.add(_cardKey(draft.front, draft.back))) {
        duplicateCards += 1;
        continue;
      }
      cards.add(draft);
    }

    if (cards.isEmpty) {
      throw const CardImportException(CardText.importJsonNoCards);
    }

    return CardImportResult(
      cards: cards,
      invalidCards: invalidCards,
      duplicateCards: duplicateCards,
    );
  }

  String _decodeUtf8(Uint8List bytes) {
    try {
      final decoded = utf8.decode(bytes);
      return decoded.startsWith('\ufeff') ? decoded.substring(1) : decoded;
    } on FormatException {
      throw const CardImportException(CardText.importJsonUnreadable);
    }
  }

  List<Object?> _readCards(String source) {
    final Object? parsed;
    try {
      parsed = jsonDecode(source);
    } on FormatException {
      throw const CardImportException(CardText.importJsonInvalid);
    }

    if (parsed is! Map<String, dynamic>) {
      throw const CardImportException(CardText.importJsonInvalid);
    }
    final version = parsed['version'];
    if (version is! int) {
      throw const CardImportException(CardText.importJsonInvalid);
    }
    if (version != 1) {
      throw const CardImportException(CardText.importJsonUnsupportedVersion);
    }
    final cards = parsed['cards'];
    if (cards is! List) {
      throw const CardImportException(CardText.importJsonInvalid);
    }
    return cards;
  }

  CardDraft? _parseDraft(Object? value) {
    if (value is! Map) return null;
    final front = value['front'];
    final back = value['back'];
    if (front is! String || back is! String) return null;

    final trimmedFront = front.trim();
    final trimmedBack = back.trim();
    if (trimmedFront.isEmpty ||
        trimmedBack.isEmpty ||
        trimmedFront.length > AppConstants.kMaxCardFront ||
        trimmedBack.length > AppConstants.kMaxCardBack) {
      return null;
    }
    return CardDraft(front: trimmedFront, back: trimmedBack);
  }

  String _cardKey(String front, String back) =>
      '${_normalize(front)}\u0000${_normalize(back)}';

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
