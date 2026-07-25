import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/backend_constants.dart';
import '../contracts/remote_database_gateway.dart';
import '../models/backend_card.dart';
import '../models/backend_chat_message.dart';
import '../models/backend_deck.dart';
import '../models/backend_exception.dart';
import '../models/backend_review.dart';

class SupabaseRemoteDatabaseGateway implements RemoteDatabaseGateway {
  const SupabaseRemoteDatabaseGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<void> insertReviews(List<BackendReview> reviews) async {
    if (reviews.isEmpty) {
      return;
    }

    // Upsert por id: revisões são imutáveis, então reenviar o mesmo lote
    // depois de uma falha parcial é seguro.
    await _client
        .from(BackendConstants.kTableReviews)
        .upsert(reviews.map(_reviewToRow).toList());
  }

  /// O PostgREST corta a resposta no `max-rows` do projeto (1000 por padrão)
  /// sem sinalizar truncamento. Como o sync infere "apagado remotamente" pela
  /// ausência da linha na resposta, uma leitura truncada apagaria os dados
  /// locais excedentes de forma permanente. Por isso toda leitura de coleção
  /// pagina até a última página.
  static const int _pageSize = 1000;

  @override
  Future<List<BackendDeck>> fetchDecks() async {
    final rows = await _fetchAllRows(
      table: BackendConstants.kTableDecks,
      orderColumn: _Columns.updatedAt,
    );

    return rows.map(_deckFromRow).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchAllRows({
    required String table,
    required String orderColumn,
    String? filterColumn,
    String? filterValue,
  }) async {
    final rows = <Map<String, dynamic>>[];
    int? total;

    while (true) {
      final base = _client.from(table).select();
      final filtered = filterColumn == null
          ? base
          : base.eq(filterColumn, filterValue!);

      // A contagem exata vem junto: não dá para confiar no tamanho da página
      // como sinal de fim, porque o `max-rows` do servidor pode ser menor que
      // [_pageSize] e cortaria a resposta silenciosamente.
      final response = await filtered
          .order(orderColumn)
          .range(rows.length, rows.length + _pageSize - 1)
          .count(CountOption.exact);

      total ??= response.count;
      rows.addAll(response.data);

      if (rows.length >= total) {
        return rows;
      }

      if (response.data.isEmpty) {
        // Sem progresso e ainda faltam linhas: preferimos falhar a devolver
        // uma coleção parcial, porque quem chama trata ausência como deleção.
        throw BackendException(
          'Sincronização incompleta de "$table": '
          '${rows.length} de $total registros.',
        );
      }
    }
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
    final rows = await _fetchAllRows(
      table: BackendConstants.kTableCards,
      orderColumn: _Columns.dueDate,
      filterColumn: _Columns.deckId,
      filterValue: deckId,
    );

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
      repetitions: (row[_Columns.repetitions] as num?)?.toInt() ?? 0,
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
      _Columns.repetitions: card.repetitions,
      _Columns.dueDate: _dateOnly(card.dueDate),
      _Columns.insight: card.insight,
      _Columns.createdAt: card.createdAt.toIso8601String(),
      _Columns.updatedAt: card.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _reviewToRow(BackendReview review) {
    return {
      _Columns.id: review.id,
      _Columns.cardId: review.cardId,
      _Columns.userId: review.userId,
      _Columns.rating: review.rating,
      _Columns.easeBefore: review.easeBefore,
      _Columns.easeAfter: review.easeAfter,
      _Columns.intervalBefore: review.intervalBefore,
      _Columns.intervalAfter: review.intervalAfter,
      _Columns.reviewedAt: review.reviewedAt.toIso8601String(),
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
  static const repetitions = 'repetitions';
  static const dueDate = 'due_date';
  static const insight = 'insight';
  static const cardId = 'card_id';
  static const rating = 'rating';
  static const easeBefore = 'ease_before';
  static const easeAfter = 'ease_after';
  static const intervalBefore = 'interval_before';
  static const intervalAfter = 'interval_after';
  static const reviewedAt = 'reviewed_at';
  static const role = 'role';
  static const content = 'content';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}
