import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../profile_text.dart';

final appVersionProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// Rodapé do perfil com a versão instalada (`version+buildNumber`).
///
/// Lê via `package_info_plus`, então acompanha o `version:` do
/// `pubspec.yaml` sem edição manual. Não mostra nada enquanto carrega ou se
/// falhar: é informação auxiliar e não pode quebrar o perfil.
class AppVersionFooter extends ConsumerWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return versionAsync.maybeWhen(
      data: (info) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
        child: Text(
          ProfileText.version(info.version, info.buildNumber),
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: isDark
                ? AppColors.textTertDark
                : AppColors.textTertiary,
          ),
        ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
