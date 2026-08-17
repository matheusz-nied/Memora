import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/deepseek_key_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/scaffold_shell.dart';
import 'api_key_text.dart';

/// Cadastro da chave da DeepSeek, exclusiva do modo local.
///
/// A chave é do usuário e a cobrança acontece na conta dele, então a tela
/// existe para deixar isso explícito: onde conseguir, onde fica guardada e
/// como tirar.
class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentKey = ref.watch(deepSeekKeyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaffoldShell(
      isDark: isDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(ApiKeyText.title),
      ),
      body: SingleChildScrollView(
        child: Responsive.constrainedContent(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(ApiKeyText.subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppDimensions.lg),
                _StatusCard(currentKey: currentKey, isDark: isDark),
                const SizedBox(height: AppDimensions.xl),
                AppInput(
                  controller: _controller,
                  label: ApiKeyText.fieldLabel,
                  hint: ApiKeyText.fieldHint,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppDimensions.sm),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.lg),
                AppButton(
                  label: ApiKeyText.save,
                  icon: Icons.key,
                  onPressed: _save,
                ),
                if (currentKey != null) ...[
                  const SizedBox(height: AppDimensions.sm),
                  AppButton(
                    label: ApiKeyText.remove,
                    icon: Icons.delete_outline,
                    variant: AppButtonVariant.secondary,
                    onPressed: _remove,
                  ),
                ],
                const SizedBox(height: AppDimensions.xl),
                Text(ApiKeyText.whereToGet, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      setState(() => _errorMessage = ApiKeyText.required);
      return;
    }

    if (!value.startsWith('sk-')) {
      setState(() => _errorMessage = ApiKeyText.invalidFormat);
      return;
    }

    setState(() => _errorMessage = null);
    await ref.read(deepSeekKeyProvider.notifier).save(value);
    if (!mounted) {
      return;
    }
    _controller.clear();
    _showSnackBar(ApiKeyText.saved);
  }

  Future<void> _remove() async {
    await ref.read(deepSeekKeyProvider.notifier).clear();
    if (!mounted) {
      return;
    }
    _controller.clear();
    setState(() => _errorMessage = null);
    _showSnackBar(ApiKeyText.removed);
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.currentKey, required this.isDark});

  final String? currentKey;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasKey = currentKey != null;

    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      showTopHighlight: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      borderColor: hasKey
          ? AppColors.primary.withValues(alpha: 0.25)
          : AppColors.glassBorderLight,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Row(
        children: [
          Icon(
            hasKey ? Icons.check_circle_outline : Icons.info_outline,
            color: hasKey
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasKey ? ApiKeyText.savedTitle : ApiKeyText.emptyTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  hasKey
                      ? ApiKeyText.savedKey(maskApiKey(currentKey!))
                      : ApiKeyText.emptyMessage,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
