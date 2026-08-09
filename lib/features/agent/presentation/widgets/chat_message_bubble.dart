import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../data/chat_message.dart';

/// A single chat message bubble.
///
/// User messages are displayed on the right with primary-tinted glass.
/// Assistant messages are displayed on the left with frosted glass.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message, this.agentName});

  final ChatMessage message;
  final String? agentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (message.isUser) {
      return _UserBubble(message: message, theme: theme, isDark: isDark);
    }

    return _AssistantBubble(
      message: message,
      agentName: agentName ?? 'Tutor IA',
      theme: theme,
      isDark: isDark,
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({
    required this.message,
    required this.theme,
    required this.isDark,
  });

  final ChatMessage message;
  final ThemeData theme;
  final bool isDark;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(AppDimensions.radiusLg),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(AppDimensions.radiusLg),
    bottomRight: Radius.circular(AppDimensions.radiusLg),
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: _radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppDimensions.glassBlur,
                  sigmaY: AppDimensions.glassBlur,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: _radius,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: isDark ? 0.82 : 0.88),
                        AppColors.primaryHover.withValues(alpha: isDark ? 0.72 : 0.78),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                      vertical: 12,
                    ),
                    child: Text(
                      message.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'Você',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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

  final ChatMessage message;
  final String agentName;
  final ThemeData theme;
  final bool isDark;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(AppDimensions.radiusLg),
    bottomLeft: Radius.circular(AppDimensions.radiusLg),
    bottomRight: Radius.circular(AppDimensions.radiusLg),
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AgentAvatar(isDark: isDark),
        const SizedBox(width: AppDimensions.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                agentName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              GlassPanel(
                isDark: isDark,
                showGlow: false,
                showTopHighlight: false,
                borderRadius: _radius,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: 12,
                ),
                child: MarkdownBody(
                  data: message.content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textPrimary,
                      height: 1.5,
                      fontSize: 15,
                    ),
                    strong: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    h1: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    h2: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    listBullet: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                    code: TextStyle(
                      color: isDark
                          ? const Color(0xFFF43F5E)
                          : const Color(0xFFBE123C),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
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
  const _AgentAvatar({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.9),
            AppColors.neonBlue.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
