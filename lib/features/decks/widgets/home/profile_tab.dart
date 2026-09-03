import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ai/deepseek_key_store.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/identity/device_user_id.dart';
import '../../../backup/backup_text.dart';
import '../../../legal/legal_links.dart';
import '../../../legal/legal_text.dart';
import '../../../profile/profile_text.dart';
import '../../../profile/widgets/app_version_footer.dart';
import '../../../profile/widgets/appearance_tile.dart';
import '../../../settings/api_key_text.dart';
import '../../deck_repository.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(decksStreamProvider);
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Responsive.constrainedContent(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Builder(
            builder: (context) {
              const displayName = DeviceUserId.displayName;
              final initial = displayName[0].toUpperCase();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimensions.sm),

                  // Premium Frosted Header Card
                  _ProfileHeaderCard(
                    displayName: displayName,
                    initial: initial,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // Live Interactive Stats Grid Row
                  Row(
                    children: [
                      // Stat 1: Total Decks Watcher
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.folder_open,
                          iconColor: AppColors.primary,
                          title: 'DECKS CRIADOS',
                          valueWidget: decksAsync.maybeWhen(
                            data: (decks) => Text(
                              '${decks.length}',
                              style: AppTypography.headingLarge.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            orElse: () => const Text('-'),
                          ),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),

                      // Stat 2: Connection live indicator
                      Expanded(
                        child: _StatBlock(
                          icon: isOnline ? Icons.wifi : Icons.wifi_off,
                          iconColor: isOnline
                              ? AppColors.success
                              : AppColors.warning,
                          title: 'CONEXÃO APP',
                          valueWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? AppColors.success
                                      : AppColors.warning,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isOnline
                                                  ? AppColors.success
                                                  : AppColors.warning)
                                              .withValues(alpha: 0.2),
                                      blurRadius: 3,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: AppTypography.headingLarge.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // Não há quota a mostrar: quem paga a IA é a chave da
                  // DeepSeek do próprio usuário, e o que importa é saber se
                  // ela está cadastrada.
                  const _ApiKeyTile(),
                  const SizedBox(height: AppDimensions.md),
                  const _BackupTile(),
                  const SizedBox(height: AppDimensions.md),
                  const AppearanceTile(),
                  const SizedBox(height: AppDimensions.md),
                  const _PrivacyTile(),
                  const SizedBox(height: AppDimensions.xl),

                  // Detailed account parameters card
                  _ProfileDetailsCard(isDark: isDark, displayName: displayName),
                  const SizedBox(height: AppDimensions.xl),

                  // Versão instalada (version+buildNumber do pubspec).
                  const AppVersionFooter(),
                  // Não há de onde sair nem conta a excluir: os dados vão
                  // embora com o app, pelo próprio sistema.
                  const SizedBox(height: 120), // Spacing for navigation bar
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENT: DEEPSEEK API KEY (LOCAL MODE)
// ==========================================
class _ApiKeyTile extends ConsumerWidget {
  const _ApiKeyTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKey = ref.watch(deepSeekKeyProvider);
    final hasKey = apiKey != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = hasKey ? AppColors.success : AppColors.warning;

    return PressableScale(
      onTap: () => context.push(RouteConstants.kRouteApiKey),
      child: GlassPanel(
        isDark: isDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        showGlow: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Icon(
                  hasKey ? Icons.key : Icons.key_off_outlined,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ApiKeyText.title,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    hasKey
                        ? ApiKeyText.savedKey(maskApiKey(apiKey))
                        : ApiKeyText.emptyTitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENT: BACKUP (LOCAL MODE)
// ==========================================
class _BackupTile extends StatelessWidget {
  const _BackupTile();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: () => context.push(RouteConstants.kRouteBackup),
      child: GlassPanel(
        isDark: isDark,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        showGlow: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.sm,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppDimensions.sm),
                child: Icon(Icons.save_alt_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    BackupText.title,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    BackupText.profileHint,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENT: PRIVACIDADE
// ==========================================
class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassPanel(
      isDark: isDark,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      showGlow: false,
      child: Column(
        children: [
          _PrivacyRow(
            isDark: isDark,
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.primary,
            title: LegalText.privacyTitle,
            subtitle: LegalText.privacyHint,
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => LegalLinks.openPrivacyPolicy(context),
          ),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.glassBorderDark
                : AppColors.glassBorderLight,
          ),
          // O canal de report é exigido pelas lojas em app generativo, e sem
          // servidor o e-mail é o único caminho que existe.
          _PrivacyRow(
            isDark: isDark,
            icon: Icons.flag_outlined,
            iconColor: AppColors.textTertiary,
            title: LegalText.reportContent,
            subtitle: LegalText.aiDisclaimer,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => LegalLinks.reportContent(context),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.sm),
                child: Icon(icon, color: iconColor),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ==========================================
// COMPONENT: PREMIUM PROFILE HEADER CARD
// ==========================================
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.displayName,
    required this.initial,
    required this.isDark,
  });

  final String displayName;
  final String initial;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Row(
        children: [
          // Styled Gradient Avatar Initials
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.headingLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.xl),

          // Profile info strings
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ProfileText.onThisDevice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecDark
                        : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENT: DYNAMIC STATISTIC CARD BLOCK
// ==========================================
class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.valueWidget,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget valueWidget;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      showGlow: false,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.textTertDark
                        : AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          valueWidget,
        ],
      ),
    );
  }
}

// ==========================================
// COMPONENT: DETAILED ACCOUNT PARAMETERS
// ==========================================
class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({required this.isDark, required this.displayName});

  final bool isDark;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      showGlow: false,
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ProfileText.account,
            style: AppTypography.headingMedium.copyWith(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          _ProfileField(
            label: ProfileText.name,
            value: displayName,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertDark : AppColors.textTertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
