import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../legal_links.dart';
import '../legal_text.dart';

/// Aviso de conteúdo gerado por IA, com o caminho para reportar.
///
/// Aparece onde o usuário está olhando para algo que o modelo escreveu — cards
/// recém-gerados, insight e chat — e não escondido numa tela de configurações.
/// É requisito de revisão da App Store para app generativo, e o report é a
/// outra metade dele: avisar que pode errar sem oferecer o que fazer a
/// respeito não conta.
class AiDisclaimerNote extends StatelessWidget {
  const AiDisclaimerNote({super.key, this.showReport = true});

  /// O report vive no perfil também; em telas onde ele já está a um toque de
  /// distância, repetir só polui.
  final bool showReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textTertiary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 14,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppDimensions.xs),
          Expanded(child: Text(LegalText.aiDisclaimer, style: style)),
          if (showReport)
            TextButton(
              onPressed: () => LegalLinks.reportContent(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(LegalText.reportContent, style: style),
            ),
        ],
      ),
    );
  }
}
