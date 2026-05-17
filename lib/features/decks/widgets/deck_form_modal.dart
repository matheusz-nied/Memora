import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input.dart';
import '../deck_model.dart';
import '../deck_text.dart';

class DeckFormModal extends StatefulWidget {
  const DeckFormModal({super.key, this.deck, required this.onSubmit});

  final DeckModel? deck;
  final Future<void> Function(String title, String? description) onSubmit;

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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppDimensions.lg,
          right: AppDimensions.lg,
          top: AppDimensions.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppDimensions.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ModalHeader(isEditing: widget.deck != null),
              const SizedBox(height: AppDimensions.xl),
              AppInput(
                controller: _titleController,
                label: DeckText.deckName,
                hint: DeckText.deckNameHint,
                icon: Icons.edit_outlined,
                textInputAction: TextInputAction.next,
                validator: _validateTitle,
              ),
              const SizedBox(height: AppDimensions.lg),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: AppConstants.kMaxDeckDescription,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  labelText: DeckText.description,
                  hintText: DeckText.descriptionHint,
                ),
                validator: _validateDescription,
              ),
              const SizedBox(height: AppDimensions.lg),
              AppButton(
                label: widget.deck == null
                    ? DeckText.createManually
                    : DeckText.save,
                icon: Icons.add_circle_outline,
                isLoading: _isSaving,
                onPressed: _submit,
              ),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(_titleController.text, _descriptionController.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            isEditing ? DeckText.editDeck : DeckText.newDeck,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
