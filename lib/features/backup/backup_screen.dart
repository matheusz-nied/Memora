import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/scaffold_shell.dart';
import 'backup_data.dart';
import 'backup_reminder.dart';
import 'backup_repository.dart';
import 'backup_text.dart';

/// Exportar e importar o conteúdo do app.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ScaffoldShell(
      isDark: isDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(BackupText.title),
      ),
      body: SingleChildScrollView(
        child: Responsive.constrainedContent(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(BackupText.subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppDimensions.xxl),
                _Section(
                  isDark: isDark,
                  title: BackupText.exportTitle,
                  description: BackupText.exportDescription,
                  action: BackupText.exportAction,
                  icon: Icons.upload_file_outlined,
                  isWorking: _isWorking,
                  onPressed: _export,
                ),
                const SizedBox(height: AppDimensions.xl),
                _Section(
                  isDark: isDark,
                  title: BackupText.importTitle,
                  description: BackupText.importDescription,
                  action: BackupText.importAction,
                  icon: Icons.download_outlined,
                  isWorking: _isWorking,
                  onPressed: _import,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _isWorking = true);
    try {
      final now = DateTime.now();
      final content = await ref
          .read(backupRepositoryProvider)
          .buildExport(exportedAt: now);

      final path = await FilePicker.saveFile(
        dialogTitle: BackupText.exportTitle,
        fileName: BackupText.fileName(now),
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: utf8.encode(content),
      );

      if (path != null) {
        await ref.read(backupReminderProvider.notifier).markExported(at: now);
      }

      _report(
        path == null
            ? BackupText.exportCanceled
            : BackupText.exportSuccess(path),
      );
    } on BackupException catch (error) {
      _report(error.message);
    } catch (error) {
      debugPrint('Falha ao exportar backup: $error');
      _report(BackupText.exportFailed);
    } finally {
      _stopWorking();
    }
  }

  Future<void> _import() async {
    setState(() => _isWorking = true);
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );

      final files = selection?.files ?? const [];
      final bytes = files.isEmpty ? null : files.first.bytes;
      if (bytes == null) {
        _report(
          selection == null
              ? BackupText.importCanceled
              : BackupText.importUnreadable,
        );
        return;
      }

      final summary = await ref
          .read(backupRepositoryProvider)
          .applyImport(utf8.decode(bytes));

      _report(
        summary.isEmpty
            ? BackupText.importNothing
            : BackupText.importSuccess(
                decks: summary.decks,
                cards: summary.cards,
                reviews: summary.reviews,
              ),
      );
    } on BackupException catch (error) {
      _report(error.message);
    } on FormatException {
      _report(BackupText.importUnreadable);
    } catch (error) {
      debugPrint('Falha ao importar backup: $error');
      _report(BackupText.importFailed);
    } finally {
      _stopWorking();
    }
  }

  void _stopWorking() {
    if (mounted) {
      setState(() => _isWorking = false);
    }
  }

  void _report(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.isDark,
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
    required this.isWorking,
    required this.onPressed,
  });

  final bool isDark;
  final String title;
  final String description;
  final String action;
  final IconData icon;
  final bool isWorking;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      showTopHighlight: false,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      borderColor: AppColors.primary.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppDimensions.xs),
          Text(description, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppDimensions.lg),
          AppButton(
            label: action,
            icon: icon,
            isLoading: isWorking,
            variant: AppButtonVariant.secondary,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
