import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/widgets/scaffold_shell.dart';
import '../generate/card_review_args.dart';
import 'card_import_repository.dart';
import 'card_text.dart';
import 'widgets/card_import_body.dart';

class CardImportScreen extends ConsumerStatefulWidget {
  const CardImportScreen({super.key, required this.deckId});

  final String deckId;

  @override
  ConsumerState<CardImportScreen> createState() => _CardImportScreenState();
}

class _CardImportScreenState extends ConsumerState<CardImportScreen> {
  var _isImporting = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaffoldShell(
      isDark: isDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(CardText.importJsonTitle),
      ),
      body: SafeArea(
        child: CardImportBody(
          isDark: isDark,
          isImporting: _isImporting,
          errorMessage: _errorMessage,
          onPickFile: _pickAndReview,
        ),
      ),
    );
  }

  Future<void> _pickAndReview() async {
    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (selection == null) {
        return;
      }

      final files = selection.files;
      final bytes = files.isEmpty ? null : files.first.bytes;
      if (bytes == null) {
        throw const CardImportException(CardText.importJsonUnreadable);
      }

      final result = await ref
          .read(cardImportRepositoryProvider)
          .importJson(deckId: widget.deckId, bytes: bytes);
      if (!mounted) {
        return;
      }

      context.push(
        RouteConstants.reviewPath(widget.deckId),
        extra: CardReviewArgs(
          deckId: widget.deckId,
          cards: result.cards,
          invalidCards: result.invalidCards,
          duplicateCards: result.duplicateCards,
          source: CardReviewSource.jsonImport,
        ),
      );
    } on CardImportException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } catch (error) {
      debugPrint('Falha ao importar cards: $error');
      if (mounted) {
        setState(() => _errorMessage = CardText.importJsonUnreadable);
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
}
