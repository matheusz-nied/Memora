import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/neon_button.dart';
import '../deck_model.dart';
import '../deck_text.dart';

class DeckFormModal extends StatefulWidget {
  const DeckFormModal({
    super.key,
    this.deck,
    required this.onSubmit,
    this.onImportJson,
  });

  final DeckModel? deck;
  final Future<String?> Function(String title, String? description) onSubmit;
  final Future<void> Function()? onImportJson;

  @override
  State<DeckFormModal> createState() => _DeckFormModalState();
}

class _DeckFormModalState extends State<DeckFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.deck?.title);
    _descriptionController = TextEditingController(
      text: widget.deck?.description,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodyLarge.copyWith(
        color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
      ),
      filled: true,
      fillColor: isDark
          ? AppColors.surfaceDeep.withValues(alpha: 0.65)
          : AppColors.primary.withValues(alpha: 0.02),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.glassBorderDark
              : AppColors.glassBorderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.lg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.deck != null;

    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radius2Xl),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.xl,
        right: AppDimensions.xl,
        top: AppDimensions.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.xl,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.glassHighlight
                        : AppColors.textPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),

              // Modal Header Title + Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? DeckText.editDeck : 'Create New Deck',
                    style: AppTypography.headingLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),

              // Deck Name Input field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppDimensions.xs,
                      bottom: AppDimensions.sm,
                    ),
                    child: Text(
                      'Deck Name',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: _titleController,
                    autofocus: !isEditing,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    textInputAction: isEditing
                        ? TextInputAction.next
                        : TextInputAction.done,
                    decoration: _fieldDecoration(
                      isDark: isDark,
                      hintText: 'e.g., Biology Midterm, Python Basics...',
                      suffixIcon: Icon(
                        Icons.edit,
                        color: isDark
                            ? AppColors.textTertDark
                            : AppColors.textTertiary,
                        size: 18,
                      ),
                    ),
                    validator: _validateTitle,
                  ),
                ],
              ),

              // If editing, we also display the description field
              if (isEditing) ...[
                const SizedBox(height: AppDimensions.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppDimensions.xs,
                        bottom: AppDimensions.sm,
                      ),
                      child: Text(
                        DeckText.description,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecDark
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: AppConstants.kMaxDeckDescription,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: _fieldDecoration(
                        isDark: isDark,
                        hintText: DeckText.descriptionHint,
                      ),
                      validator: _validateDescription,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppDimensions.xl),

              // Action buttons based on creation or editing
              if (!isEditing) ...[
                if (_isSaving)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDimensions.lg),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  NeonButton(
                    label: 'Generate with AI',
                    icon: Icons.auto_awesome,
                    onPressed: () => _submit(isAiGeneration: true),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Outline button: Create Manually
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      minimumSize: const Size.fromHeight(56),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.glassBorderDark
                            : AppColors.glassBorderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                    ),
                    onPressed: () => _submit(isAiGeneration: false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_circle, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Create Manually',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onImportJson != null) ...[
                    const SizedBox(height: AppDimensions.sm),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.md,
                          vertical: AppDimensions.sm,
                        ),
                      ),
                      onPressed: _importJson,
                      child: Text(
                        DeckText.importDecksJson,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],


              ] else ...[
                _isSaving
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppDimensions.lg,
                          ),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : NeonButton(
                        label: 'Salvar Alterações',
                        icon: Icons.check_circle_outline,
                        onPressed: () => _submit(isAiGeneration: false),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _validateTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return DeckText.titleRequired;
    }
    if (trimmed.length > AppConstants.kMaxDeckTitle) {
      return DeckText.titleTooLong;
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if ((value?.trim().length ?? 0) > AppConstants.kMaxDeckDescription) {
      return DeckText.descriptionTooLong;
    }
    return null;
  }

  Future<void> _submit({required bool isAiGeneration}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final deckId = await widget.onSubmit(
        _titleController.text,
        _descriptionController.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
        if (isAiGeneration && deckId != null) {
          // Push directly to card generator screen
          GoRouter.of(context).push(RouteConstants.generatePath(deckId));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _importJson() async {
    final onImportJson = widget.onImportJson;
    if (onImportJson == null) {
      return;
    }
    Navigator.of(context).pop();
    await onImportJson();
  }
}
