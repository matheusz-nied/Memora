import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/backend/models/ai_chat_message.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/connectivity_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../decks/deck_repository.dart';
import '../data/agent_repository.dart';
import '../data/agent_text.dart';
import '../data/chat_message.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/typing_indicator.dart';
import '../../legal/widgets/ai_disclaimer_note.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  var _isLoadingHistory = true;
  var _isSending = false;
  var _hasHistoryError = false;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _messageCount => _messages.length;
  bool get _isAtLimit => _messageCount >= AppConstants.kMaxChatMessages;

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(deckStreamProvider(widget.deckId));
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    final deckTitle = deckAsync.maybeWhen(
      data: (d) => d?.title ?? AgentText.chatTitle,
      orElse: () => AgentText.chatTitle,
    );
    final agentName = deckAsync.maybeWhen(
      data: (d) => d?.agentName,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              AgentText.deckLabel.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              deckTitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<_ChatAction>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (action) {
              switch (action) {
                case _ChatAction.newConversation:
                  _startNewConversation();
                case _ChatAction.agentConfig:
                  context.push(RouteConstants.agentConfigPath(widget.deckId));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ChatAction.newConversation,
                child: Text(AgentText.newConversation),
              ),
              PopupMenuItem(
                value: _ChatAction.agentConfig,
                child: Text(AgentText.agentConfig),
              ),
            ],
          ),
        ],
      ),
      body: Responsive.constrainedContent(
        child: Column(
          children: [
            // Offline banner
            if (!isOnline)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.lg,
                  AppDimensions.sm,
                  AppDimensions.lg,
                  0,
                ),
                child: const OfflineBanner(message: AgentText.offline),
              ),

            // Messages area
            Expanded(child: _buildBody(agentName)),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
              child: const AiDisclaimerNote(showReport: false),
            ),

            // Message limit warning
            if (_isAtLimit)
              _MessageLimitBanner(onNewConversation: _startNewConversation),

            // Send error
            if (_sendError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.xs,
                ),
                child: Text(
                  _sendError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ),

            // Input bar
            ChatInputBar(
              controller: _inputController,
              enabled: isOnline && !_isAtLimit,
              isSending: _isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String? agentName) {
    if (_isLoadingHistory) {
      return const LoadingState();
    }

    if (_hasHistoryError) {
      return ErrorState(message: AgentText.historyError, onRetry: _loadHistory);
    }

    if (_messages.isEmpty && !_isSending) {
      return const EmptyState(
        title: AgentText.chatTitle,
        message: AgentText.emptyChat,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        // Typing indicator at the bottom
        if (_isSending && index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.only(top: AppDimensions.md),
            child: TypingIndicator(),
          );
        }

        final message = _messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.md),
          child: ChatMessageBubble(message: message, agentName: agentName),
        );
      },
    );
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _hasHistoryError = false;
    });

    try {
      final repository = ref.read(agentRepositoryProvider);
      final history = await repository.fetchChatHistory(widget.deckId);
      if (mounted) {
        setState(() {
          _messages = history.reversed.toList();
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _hasHistoryError = true;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending || _isAtLimit) return;

    _inputController.clear();
    setState(() {
      _isSending = true;
      _sendError = null;
    });

    // Add user message to UI immediately
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    setState(() => _messages.add(userMessage));
    _scrollToBottom();

    try {
      final repository = ref.read(agentRepositoryProvider);

      // Save user message to backend
      await repository.saveChatMessage(
        deckId: widget.deckId,
        role: ChatRole.user,
        content: text,
      );

      // Prepare message history for AI
      final aiMessages = _messages
          .map((m) => AiChatMessage(role: m.role, content: m.content))
          .toList();

      // Send to AI
      final reply = await repository.sendMessage(
        deckId: widget.deckId,
        messages: aiMessages,
        userMessage: text,
      );

      // Save assistant reply to backend
      await repository.saveChatMessage(
        deckId: widget.deckId,
        role: ChatRole.assistant,
        content: reply,
      );

      // Add assistant message to UI
      if (mounted) {
        final assistantMessage = ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.assistant,
          content: reply,
          createdAt: DateTime.now(),
        );
        setState(() {
          _messages.add(assistantMessage);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendError = _readableError(error);
        });
      }
    }
  }

  void _startNewConversation() {
    setState(() {
      _messages = [];
      _sendError = null;
      _inputController.clear();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _readableError(Object error) {
    final message = error.toString();
    return message
        .replaceFirst('BackendException: ', '')
        .replaceFirst('Exception: ', '');
  }
}

enum _ChatAction { newConversation, agentConfig }

class _MessageLimitBanner extends StatelessWidget {
  const _MessageLimitBanner({required this.onNewConversation});

  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.sm,
      ),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: AppDimensions.xl,
              ),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  AgentText.messageLimitTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            AgentText.messageLimitMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppDimensions.sm),
          TextButton.icon(
            onPressed: onNewConversation,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(AgentText.newConversation),
          ),
        ],
      ),
    );
  }
}
