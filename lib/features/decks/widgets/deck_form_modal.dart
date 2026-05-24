import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../deck_model.dart';
import '../deck_text.dart';

class DeckFormModal extends StatefulWidget {
  const DeckFormModal({super.key, this.deck, required this.onSubmit});

  final DeckModel? deck;
  final Future<String?> Function(String title, String? description) onSubmit;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.deck != null;

    // Slate color definitions matching Tailwind CSS colors
    const slate300 = Color(0xFFCBD5E1);
    const slate400 = Color(0xFF94A3B8);
    const slate600 = Color(0xFF475569);
    const slate700 = Color(0xFF334155);
    const slate800 = Color(0xFF1E293B);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151B26) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppDimensions.xl,
            right: AppDimensions.xl,
            top: AppDimensions.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.xl,
          ),
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
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.15),
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
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 24,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? slate400 : slate600,
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
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'Deck Name',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? slate400 : slate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: _titleController,
                      autofocus: !isEditing,
                      style: AppTypography.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      textInputAction: isEditing
                          ? TextInputAction.next
                          : TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'e.g., Biology Midterm, Python Basics...',
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: isDark ? slate700 : slate400,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1A2230)
                            : AppColors.primary.withOpacity(0.02),
                        suffixIcon: Icon(
                          Icons.edit,
                          color: isDark ? slate600 : slate400,
                          size: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? slate800
                                : Colors.black.withOpacity(0.08),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.lg,
                          vertical: 16,
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
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          DeckText.description,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark ? slate400 : slate600,
                            fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        maxLength: AppConstants.kMaxDeckDescription,
                        style: AppTypography.bodyLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: DeckText.descriptionHint,
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: isDark ? slate600 : slate400,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1A2230)
                              : AppColors.primary.withOpacity(0.02),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? slate800
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.lg,
                            vertical: 14,
                          ),
                        ),
                        validator: _validateDescription,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppDimensions.xl),

                // Action buttons based on creation or editing
                if (!isEditing) ...[
                  // Primary Blue button: Generate with AI
                  _isSaving
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ).copyWith(
                                // Simulated pulse glow visual style border
                                side: MaterialStateProperty.all(
                                  BorderSide(
                                    color: AppColors.primary.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                              ),
                              onPressed: () => _submit(isAiGeneration: true),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.auto_awesome, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Generate with AI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppDimensions.md),

                            // Outline button: Create Manually
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? slate300
                                    : AppColors.textPrimary,
                                minimumSize: const Size.fromHeight(56),
                                side: BorderSide(
                                  color: isDark
                                      ? slate800
                                      : Colors.black.withOpacity(0.12),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                          ],
                        ),

                  const SizedBox(height: AppDimensions.xl),
                  // Footer explanatory text
                  Text(
                    'AI generation uses your notes or topic to create cards automatically.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? slate600 : slate400,
                      fontSize: 11,
                    ),
                  ),
                ] else ...[
                  // If editing: single solid save button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _submit(isAiGeneration: false),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Salvar Alterações',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
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
}
