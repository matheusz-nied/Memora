import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../data/agent_text.dart';

/// Bottom input bar for the chat screen.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.isDark,
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.isSending,
  });

  final bool isDark;
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      showTopHighlight: true,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.radius2Xl),
        topRight: Radius.circular(AppDimensions.radius2Xl),
      ),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 11,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TUTOR ATIVO • Consultando cards do deck',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecDark
                            : AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled && !isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: AgentText.inputPlaceholder,
                      hintStyle: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.textTertDark
                            : AppColors.textTertiary,
                      ),
                      suffixIcon: Icon(
                        Icons.mic_none_outlined,
                        color: isDark
                            ? AppColors.textTertDark
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXl),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.glassBorderDark
                              : AppColors.glassBorderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXl),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.glassBorderDark
                              : AppColors.glassBorderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXl),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.lg,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDeep.withValues(alpha: 0.5)
                          : AppColors.surface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                _SendButton(
                  onPressed: enabled && !isSending ? onSend : null,
                  isSending: isSending,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed, required this.isSending});

  final VoidCallback? onPressed;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final active = onPressed != null;

    return PressableScale(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? AppColors.primary
              : AppColors.borderDarkStrong.withValues(alpha: 0.35),
        ),
        child: Center(
          child: isSending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.arrow_upward,
                  color: active ? Colors.white : AppColors.textTertiary,
                  size: 20,
                ),
        ),
      ),
    );
  }
}
