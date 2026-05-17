import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../card_model.dart';
import '../card_text.dart';

class CardFormModal extends StatefulWidget {
  const CardFormModal({super.key, this.card, required this.onSubmit});

  final CardModel? card;
  final Future<void> Function(String front, String back) onSubmit;

  @override
  State<CardFormModal> createState() => _CardFormModalState();
}

class _CardFormModalState extends State<CardFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.front);
    _backController = TextEditingController(text: widget.card?.back);
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(CardText.cancel),
        ),
        leadingWidth: AppDimensions.huge * 2,
        title: Text(widget.card == null ? CardText.newCard : CardText.editCard),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: AppDimensions.xl,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(CardText.save),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.xxl),
            children: [
              _CardTextArea(
                controller: _frontController,
                label: CardText.front,
                hint: CardText.frontHint,
                maxLength: AppConstants.kMaxCardFront,
                minLines: 4,
                validator: _validateFront,
                textStyle: AppTypography.headingLarge,
              ),
              const Divider(height: AppDimensions.xxxl),
              _CardTextArea(
                controller: _backController,
                label: CardText.back,
                hint: CardText.backHint,
                maxLength: AppConstants.kMaxCardBack,
                minLines: 8,
                validator: _validateBack,
                textStyle: AppTypography.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateFront(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return CardText.frontRequired;
    }
    if (trimmed.length > AppConstants.kMaxCardFront) {
      return CardText.frontTooLong;
    }
    return null;
  }

  String? _validateBack(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return CardText.backRequired;
    }
    if (trimmed.length > AppConstants.kMaxCardBack) {
      return CardText.backTooLong;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(_frontController.text, _backController.text);
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

class _CardTextArea extends StatelessWidget {
  const _CardTextArea({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
    required this.minLines,
    required this.validator,
    required this.textStyle,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;
  final int minLines;
  final FormFieldValidator<String> validator;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      maxLength: maxLength,
      validator: validator,
      style: textStyle.copyWith(fontSize: textStyle.fontSize?.clamp(16, 32)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}
