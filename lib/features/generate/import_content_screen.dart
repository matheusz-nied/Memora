import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/offline_banner.dart';
import 'generate_repository.dart';
import 'generate_text.dart';
import 'generated_cards_review_args.dart';
import 'widgets/quantity_selector.dart';

enum _GenerateMode { text, pdf }

class ImportContentScreen extends ConsumerStatefulWidget {
  const ImportContentScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<ImportContentScreen> createState() =>
      _ImportContentScreenState();
}

class _ImportContentScreenState extends ConsumerState<ImportContentScreen> {
  final _textController = TextEditingController();
  var _mode = _GenerateMode.text;
  var _quantity = AppConstants.kCardQuantityOptions.first;
  var _isGenerating = false;
  String? _errorMessage;
  String? _pdfName;
  Uint8List? _pdfBytes;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return Scaffold(
      appBar: AppBar(title: const Text(GenerateText.title)),
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: ListView(
            padding: Responsive.contentPadding(context),
            children: [
              if (!isOnline) ...[
                const OfflineBanner(message: GenerateText.offline),
                const SizedBox(height: AppDimensions.lg),
              ],
              Text(
                GenerateText.importTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                GenerateText.importSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppDimensions.xl),
              SegmentedButton<_GenerateMode>(
                segments: const [
                  ButtonSegment(
                    value: _GenerateMode.text,
                    label: Text(GenerateText.textMode),
                    icon: Icon(Icons.notes),
                  ),
                  ButtonSegment(
                    value: _GenerateMode.pdf,
                    label: Text(GenerateText.pdfMode),
                    icon: Icon(Icons.picture_as_pdf_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selected) {
                  setState(() {
                    _mode = selected.single;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: AppDimensions.xl),
              if (_mode == _GenerateMode.text)
                _TextInput(controller: _textController)
              else
                _PdfPicker(pdfName: _pdfName, onPick: _pickPdf),
              const SizedBox(height: AppDimensions.xl),
              QuantitySelector(
                value: _quantity,
                onChanged: (value) => setState(() => _quantity = value),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppDimensions.lg),
                Text(
                  _errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppDimensions.xxl),
              AppButton(
                label: _isGenerating
                    ? GenerateText.generating
                    : GenerateText.generate,
                icon: Icons.auto_awesome,
                isLoading: _isGenerating,
                onPressed: isOnline && !_isGenerating ? _generate : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      return;
    }

    setState(() {
      _pdfName = file.name;
      _pdfBytes = file.bytes;
      _errorMessage = null;
    });
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(generateRepositoryProvider);
      final cards = switch (_mode) {
        _GenerateMode.text => await repository.generateFromText(
          deckId: widget.deckId,
          text: _textController.text,
          quantity: _quantity,
        ),
        _GenerateMode.pdf => await repository.generateFromPdf(
          deckId: widget.deckId,
          fileName: _pdfName ?? '',
          bytes: _pdfBytes ?? Uint8List(0),
          quantity: _quantity,
        ),
      };

      if (mounted) {
        context.push(
          RouteConstants.reviewPath(widget.deckId),
          extra: GeneratedCardsReviewArgs(deckId: widget.deckId, cards: cards),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  String _readableError(Object error) {
    final message = error.toString().replaceFirst('BackendException: ', '');
    return message.replaceFirst('Exception: ', '');
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 8,
      maxLines: 14,
      maxLength: AppConstants.kMaxTextInput,
      decoration: const InputDecoration(
        labelText: GenerateText.sourceTextLabel,
        hintText: GenerateText.sourceTextHint,
        alignLabelWithHint: true,
      ),
    );
  }
}

class _PdfPicker extends StatelessWidget {
  const _PdfPicker({required this.pdfName, required this.onPick});

  final String? pdfName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasPdf = pdfName != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.primary,
              size: AppDimensions.huge,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              hasPdf ? GenerateText.selectedPdf : GenerateText.selectPdf,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (hasPdf) ...[
              const SizedBox(height: AppDimensions.sm),
              Text(
                pdfName!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppDimensions.lg),
            AppButton(
              label: hasPdf ? GenerateText.changePdf : GenerateText.selectPdf,
              icon: Icons.upload_file,
              onPressed: onPick,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}
