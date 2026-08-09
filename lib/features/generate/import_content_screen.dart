import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/backend/models/backend_exception.dart';
import '../../core/backend/models/generated_card.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/connectivity_service.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/scaffold_shell.dart';
import '../../core/widgets/soft_progress_bar.dart';
import 'generate_repository.dart';
import 'generate_text.dart';
import 'generated_cards_review_args.dart';
import 'generation_progress.dart';
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
  GenerateProgress? _progress;
  String? _errorMessage;
  String? _pdfName;
  Uint8List? _pdfBytes;

  bool get _isGenerating => _progress != null;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return ScaffoldShell(
      isDark: isDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          GenerateText.title,
          style: AppTypography.headingMedium.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
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
              GlassPanel(
                isDark: isDark,
                showGlow: false,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: SegmentedButton<_GenerateMode>(
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
              ),
              const SizedBox(height: AppDimensions.xl),
              if (_mode == _GenerateMode.text)
                _TextInput(isDark: isDark, controller: _textController)
              else
                _PdfPicker(isDark: isDark, pdfName: _pdfName, onPick: _pickPdf),
              const SizedBox(height: AppDimensions.xl),
              GlassPanel(
                isDark: isDark,
                showGlow: false,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: QuantitySelector(
                  value: _quantity,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
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
              if (_progress case final progress?) ...[
                const SizedBox(height: AppDimensions.lg),
                _GenerateProgressIndicator(
                  progress: progress,
                  isDark: isDark,
                ),
              ],
              const SizedBox(height: AppDimensions.xxl),
              NeonButton(
                label: _isGenerating
                    ? GenerateText.generating
                    : GenerateText.generate,
                icon: Icons.auto_awesome,
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
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return;
    }

    final rejection = await _pdfRejection(bytes);
    if (!mounted) {
      return;
    }

    setState(() {
      _errorMessage = rejection;
      _pdfName = rejection == null ? file.name : null;
      _pdfBytes = rejection == null ? bytes : null;
    });
  }

  /// Barra o arquivo aqui em vez de deixar o servidor recusar: subir 20 MB
  /// para receber "páginas demais" gasta a franquia de dados do usuário.
  Future<String?> _pdfRejection(Uint8List bytes) async {
    if (bytes.length > AppConstants.kMaxPdfSizeMb * 1024 * 1024) {
      return GenerateText.pdfTooLarge;
    }

    try {
      final document = await PdfDocument.openData(bytes);
      final pages = document.pagesCount;
      await document.close();
      if (pages > AppConstants.kMaxPdfPages) {
        return GenerateText.pdfTooManyPages;
      }
    } catch (_) {
      // Contar páginas é adiantamento, não autoridade: se a plataforma não
      // conseguir abrir o arquivo aqui, o servidor decide.
      return null;
    }

    return null;
  }

  Future<void> _generate() async {
    setState(() {
      _progress = _initialProgress();
      _errorMessage = null;
    });

    try {
      final repository = ref.read(generateRepositoryProvider);
      void onProgress(GenerateProgress progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      }

      final result = switch (_mode) {
        _GenerateMode.text => await repository.generateFromText(
          deckId: widget.deckId,
          text: _textController.text,
          quantity: _quantity,
          onProgress: onProgress,
        ),
        _GenerateMode.pdf => await repository.generateFromPdf(
          deckId: widget.deckId,
          fileName: _pdfName ?? '',
          bytes: _pdfBytes ?? Uint8List(0),
          quantity: _quantity,
          onProgress: onProgress,
        ),
      };

      if (!mounted) {
        return;
      }

      if (result.isComplete) {
        _openReview(result.cards);
        return;
      }

      final reason = _readableError(result.error!);
      if (result.isPartial) {
        await _offerPartialCards(cards: result.cards, reason: reason);
        return;
      }

      setState(() => _errorMessage = reason);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _readableError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _progress = null);
      }
    }
  }

  GenerateProgress _initialProgress() {
    return GenerateProgress(
      phase: _mode == _GenerateMode.pdf
          ? GeneratePhase.extracting
          : GeneratePhase.generating,
      batchesDone: 0,
      batchesTotal: 0,
      cardsDone: 0,
      cardsRequested: _quantity,
    );
  }

  /// Um lote falhou no meio do caminho, mas os anteriores já foram gerados e
  /// cobrados. Jogá-los fora sem perguntar faria o usuário pagar de novo pelo
  /// mesmo material.
  Future<void> _offerPartialCards({
    required List<GeneratedCard> cards,
    required String reason,
  }) async {
    final keep = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(GenerateText.partialTitle),
        content: Text(
          GenerateText.partialMessage(cards: cards.length, reason: reason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(GenerateText.discardPartialCards),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(GenerateText.usePartialCards),
          ),
        ],
      ),
    );

    if (!mounted) {
      return;
    }

    if (keep ?? false) {
      _openReview(cards);
    } else {
      setState(() => _errorMessage = reason);
    }
  }

  void _openReview(List<GeneratedCard> cards) {
    context.push(
      RouteConstants.reviewPath(widget.deckId),
      extra: GeneratedCardsReviewArgs(deckId: widget.deckId, cards: cards),
    );
  }

  String _readableError(Object error) {
    if (error is BackendException) {
      if (error.isRateLimited) {
        return GenerateText.rateLimited;
      }
      if (error.isTimeout) {
        return GenerateText.aiTimeout;
      }
      return error.message;
    }

    final message = error.toString().replaceFirst('BackendException: ', '');
    return message.replaceFirst('Exception: ', '');
  }
}

class _GenerateProgressIndicator extends StatelessWidget {
  const _GenerateProgressIndicator({
    required this.progress,
    required this.isDark,
  });

  final GenerateProgress progress;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label = switch (progress.phase) {
      GeneratePhase.extracting => GenerateText.extractingPdf,
      GeneratePhase.generating when progress.batchesTotal > 1 =>
        GenerateText.generatingBatch(
          // No último aviso todos os lotes já terminaram; sem o teto o texto
          // anunciaria um lote 5 de 4.
          batch: (progress.batchesDone + 1).clamp(1, progress.batchesTotal),
          batches: progress.batchesTotal,
          cards: progress.cardsDone,
          requested: progress.cardsRequested,
        ),
      GeneratePhase.generating => GenerateText.generating,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SoftProgressBar(progress: progress.fraction ?? 0.0, isDark: isDark),
        const SizedBox(height: AppDimensions.sm),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({required this.isDark, required this.controller});

  final bool isDark;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: TextField(
        controller: controller,
        minLines: 8,
        maxLines: 14,
        maxLength: AppConstants.kMaxTextInput,
        style: AppTypography.bodyLarge,
        decoration: const InputDecoration(
          labelText: GenerateText.sourceTextLabel,
          hintText: GenerateText.sourceTextHint,
          alignLabelWithHint: true,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _PdfPicker extends StatelessWidget {
  const _PdfPicker({
    required this.isDark,
    required this.pdfName,
    required this.onPick,
  });

  final bool isDark;
  final String? pdfName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasPdf = pdfName != null;
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
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
    );
  }
}
