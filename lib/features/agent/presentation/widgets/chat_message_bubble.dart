import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../chat_message_ui.dart';

/// A single chat message bubble.
///
/// User messages are displayed on the right with primary color.
/// Assistant messages are displayed on the left with surface color.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.agentName,
  });

  final ChatMessageUi message;
  final String? agentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (message.isUser) {
      return _UserBubble(message: message, theme: theme);
    }

    return _AssistantBubble(
      message: message,
      agentName: agentName ?? 'Agente',
      theme: theme,
      isDark: isDark,
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.theme});

  final ChatMessageUi message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusLg),
              topRight: Radius.circular(AppDimensions.radiusSm),
              bottomLeft: Radius.circular(AppDimensions.radiusLg),
              bottomRight: Radius.circular(AppDimensions.radiusLg),
            ),
          ),
          child: Text(
            message.content,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({
    required this.message,
    required this.agentName,
    required this.theme,
    required this.isDark,
  });

  final ChatMessageUi message;
  final String agentName;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgentAvatar(),
        const SizedBox(width: AppDimensions.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agentName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.md,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusSm),
                    topRight: Radius.circular(AppDimensions.radiusLg),
                    bottomLeft: Radius.circular(AppDimensions.radiusLg),
                    bottomRight: Radius.circular(AppDimensions.radiusLg),
                  ),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Text(
                  message.content,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: AppDimensions.xs),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
