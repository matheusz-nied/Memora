import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../auth_repository.dart';
import '../profile_text.dart';

/// Exclusão de conta a partir do perfil.
///
/// Obrigatória para publicar na App Store quando o app cria conta
/// (guideline 5.1.1(v)). A confirmação é em dois passos — diálogo mais
/// digitação da palavra — porque a ação é irreversível.
class DeleteAccountButton extends ConsumerStatefulWidget {
  const DeleteAccountButton({super.key});

  @override
  ConsumerState<DeleteAccountButton> createState() =>
      _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<DeleteAccountButton> {
  var _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.minTouchTarget,
      child: TextButton.icon(
        onPressed: _isDeleting ? null : _confirmAndDelete,
        icon: _isDeleting
            ? const SizedBox(
                width: AppDimensions.lg,
                height: AppDimensions.lg,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_forever_outlined, size: 20),
        label: Text(
          ProfileText.deleteAccount,
          style: AppTypography.labelMedium.copyWith(color: AppColors.error),
        ),
        style: TextButton.styleFrom(foregroundColor: AppColors.error),
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      // O router redireciona para o login sozinho quando a sessão cai.
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(readableAuthError(error)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  var _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final matches =
          _controller.text.trim().toUpperCase() ==
          ProfileText.deleteConfirmationWord;
      if (matches != _canConfirm) {
        setState(() => _canConfirm = matches);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(ProfileText.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(ProfileText.deleteAccountWarning),
          const SizedBox(height: AppDimensions.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            // 16px evita o zoom automático no iOS.
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: ProfileText.deleteConfirmationLabel,
              hintText: ProfileText.deleteConfirmationWord,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(ProfileText.cancel),
        ),
        TextButton(
          onPressed: _canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text(ProfileText.deleteAccountConfirm),
        ),
      ],
    );
  }
}
