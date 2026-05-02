import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/backend_constants.dart';
import '../contracts/remote_database_gateway.dart';
import '../models/backend_card.dart';
import '../models/backend_chat_message.dart';
import '../models/backend_deck.dart';

class SupabaseRemoteDatabaseGateway implements RemoteDatabaseGateway {
  const SupabaseRemoteDatabaseGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<BackendDeck>> fetchDecks() async {
    final rows = await _client
        .from(BackendConstants.kTableDecks)
        .select()
        .order(_Columns.updatedAt);

    return rows.map(_deckFromRow).toList();
  }

  @override
  Future<BackendDeck> upsertDeck(BackendDeck deck) async {
    final row = await _client
        .from(BackendConstants.kTableDecks)
        .upsert(_deckToRow(deck))
        .select()
        .single();

    return _deckFromRow(row);
  }

  @override
  Future<void> deleteDeck(String deckId) async {
    await _client
        .from(BackendConstants.kTableDecks)
        .delete()
        .eq(_Columns.id, deckId);
  }

  @override
  Future<List<BackendCard>> fetchCards(String deckId) async {
    final rows = await _client
        .from(BackendConstants.kTableCards)
        .select()
        .eq(_Columns.deckId, deckId)
        .order(_Columns.dueDate);

    return rows.map(_cardFromRow).toList();
  }

  @override
  Future<BackendCard> upsertCard(BackendCard card) async {
    final row = await _client
        .from(BackendConstants.kTableCards)
        .upsert(_cardToRow(card))
        .select()
        .single();

    return _cardFromRow(row);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await _client
        .from(BackendConstants.kTableCards)
        .delete()
        .eq(_Columns.id, cardId);
  }

  @override
  Future<BackendCard> updateCardProgress({
    required String cardId,
    required double easeFactor,
    required int intervalDays,
    required DateTime dueDate,
    required DateTime updatedAt,
  }) async {
    final row = await _client
        .from(BackendConstants.kTableCards)
        .update({
          _Columns.easeFactor: easeFactor,
          _Columns.intervalDays: intervalDays,
          _Columns.dueDate: _dateOnly(dueDate),
          _Columns.updatedAt: updatedAt.toIso8601String(),
        })
        .eq(_Columns.id, cardId)
        .select()
        .single();

    return _cardFromRow(row);
  }

  @override
  Future<BackendCard> updateCardInsight({
    required String cardId,
    required String insight,
    required DateTime updatedAt,
  }) async {
    final row = await _client
        .from(BackendConstants.kTableCards)
        .update({
          _Columns.insight: insight,
          _Columns.updatedAt: updatedAt.toIso8601String(),
        })
        .eq(_Columns.id, cardId)
        .select()
        .single();

    return _cardFromRow(row);
  }

  @override
  Future<List<BackendChatMessage>> fetchChatMessages(String deckId) async {
    final rows = await _client
        .from(BackendConstants.kTableChatMessages)
        .select()
        .eq(_Columns.deckId, deckId)
        .order(_Columns.createdAt);

    return rows.map(_chatMessageFromRow).toList();
  }

  @override
  Future<BackendChatMessage> insertChatMessage(
    BackendChatMessage message,
  ) async {
    final row = await _client
        .from(BackendConstants.kTableChatMessages)
        .insert(_chatMessageToRow(message))
        .select()
        .single();

    return _chatMessageFromRow(row);
  }

  BackendDeck _deckFromRow(Map<String, dynamic> row) {
    return BackendDeck(
      id: row[_Columns.id] as String,
      userId: row[_Columns.userId] as String,
      title: row[_Columns.title] as String,
      description: row[_Columns.description] as String?,
      agentName: row[_Columns.agentName] as String,
      agentPrompt: row[_Columns.agentPrompt] as String?,
      agentTemplate: row[_Columns.agentTemplate] as String,
      agentLanguage: row[_Columns.agentLanguage] as String,
      agentLevel: row[_Columns.agentLevel] as String,
      createdAt: DateTime.parse(row[_Columns.createdAt] as String),
      updatedAt: DateTime.parse(row[_Columns.updatedAt] as String),
    );
  }

  Map<String, dynamic> _deckToRow(BackendDeck deck) {
    return {
      _Columns.id: deck.id,
      _Columns.userId: deck.userId,
      _Columns.title: deck.title,
      _Columns.description: deck.description,
      _Columns.agentName: deck.agentName,
      _Columns.agentPrompt: deck.agentPrompt,
      _Columns.agentTemplate: deck.agentTemplate,
      _Columns.agentLanguage: deck.agentLanguage,
      _Columns.agentLevel: deck.agentLevel,
      _Columns.createdAt: deck.createdAt.toIso8601String(),
      _Columns.updatedAt: deck.updatedAt.toIso8601String(),
    };
  }

  BackendCard _cardFromRow(Map<String, dynamic> row) {
    return BackendCard(
      id: row[_Columns.id] as String,
      deckId: row[_Columns.deckId] as String,
      front: row[_Columns.front] as String,
      back: row[_Columns.back] as String,
      easeFactor: (row[_Columns.easeFactor] as num).toDouble(),
      intervalDays: row[_Columns.intervalDays] as int,
      dueDate: DateTime.parse(row[_Columns.dueDate] as String),
      insight: row[_Columns.insight] as String?,
      createdAt: DateTime.parse(row[_Columns.createdAt] as String),
      updatedAt: DateTime.parse(row[_Columns.updatedAt] as String),
    );
  }

  Map<String, dynamic> _cardToRow(BackendCard card) {
    return {
      _Columns.id: card.id,
      _Columns.deckId: card.deckId,
      _Columns.front: card.front,
      _Columns.back: card.back,
      _Columns.easeFactor: card.easeFactor,
      _Columns.intervalDays: card.intervalDays,
      _Columns.dueDate: _dateOnly(card.dueDate),
      _Columns.insight: card.insight,
      _Columns.createdAt: card.createdAt.toIso8601String(),
      _Columns.updatedAt: card.updatedAt.toIso8601String(),
    };
  }

  BackendChatMessage _chatMessageFromRow(Map<String, dynamic> row) {
    return BackendChatMessage(
      id: row[_Columns.id] as String,
      deckId: row[_Columns.deckId] as String,
      userId: row[_Columns.userId] as String,
      role: _chatRoleFromName(row[_Columns.role] as String),
      content: row[_Columns.content] as String,
      createdAt: DateTime.parse(row[_Columns.createdAt] as String),
    );
  }

  Map<String, dynamic> _chatMessageToRow(BackendChatMessage message) {
    return {
      _Columns.id: message.id,
      _Columns.deckId: message.deckId,
      _Columns.userId: message.userId,
      _Columns.role: message.role.name,
      _Columns.content: message.content,
      _Columns.createdAt: message.createdAt.toIso8601String(),
    };
  }

  BackendChatRole _chatRoleFromName(String name) {
    return BackendChatRole.values.firstWhere(
      (role) => role.name == name,
      orElse: () => BackendChatRole.user,
    );
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}

class _Columns {
  const _Columns._();

  static const id = 'id';
  static const userId = 'user_id';
  static const deckId = 'deck_id';
  static const title = 'title';
  static const description = 'description';
  static const agentName = 'agent_name';
  static const agentPrompt = 'agent_prompt';
  static const agentTemplate = 'agent_template';
  static const agentLanguage = 'agent_language';
  static const agentLevel = 'agent_level';
  static const front = 'front';
  static const back = 'back';
  static const easeFactor = 'ease_factor';
  static const intervalDays = 'interval_days';
  static const dueDate = 'due_date';
  static const insight = 'insight';
  static const role = 'role';
  static const content = 'content';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}
