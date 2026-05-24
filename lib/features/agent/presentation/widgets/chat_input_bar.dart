import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/agent_text.dart';

/// Bottom input bar for the chat screen.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.enabled,
    required this.isSending,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: AgentText.inputPlaceholder,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius2Xl),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius2Xl),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius2Xl),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.md,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surface,
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
    return SizedBox(
      width: AppDimensions.huge,
      height: AppDimensions.huge,
      child: Material(
        color: onPressed != null ? AppColors.primary : AppColors.textTertiary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: isSending
                ? const SizedBox.square(
                    dimension: AppDimensions.xl,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: AppDimensions.xxl,
                  ),
          ),
        ),
      ),
    );
  }
}
