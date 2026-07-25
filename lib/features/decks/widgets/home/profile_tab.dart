import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/connectivity_service.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../auth/auth_repository.dart';
import '../../../auth/profile_text.dart';
import '../../../auth/widgets/delete_account_button.dart';
import '../../../quota/widgets/ai_quota_card.dart';
import '../../deck_repository.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({
    super.key,
    required this.isDark,
    required this.isSigningOut,
    required this.onSignOut,
  });

  final bool isDark;
  final bool isSigningOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(authStateProvider);
    final decksAsync = ref.watch(decksStreamProvider);
    final isOnline = ref
        .watch(onlineStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => true);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Responsive.constrainedContent(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: sessionState.when(
              loading: () => const LoadingState(),
              error: (_, __) =>
                  const ErrorState(message: ProfileText.sessionUnavailable),
              data: (session) {
                if (session == null) {
                  return const ErrorState(
                    message: ProfileText.sessionUnavailable,
                  );
                }

                final user = session.user;
                final displayName = user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!
                    : ProfileText.authenticatedUser;
                final email = user.email?.trim().isNotEmpty == true
                    ? user.email!
                    : ProfileText.noEmail;

                // Extract name initials
                final initial = displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : 'A';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppDimensions.sm),

                    // Premium Frosted Header Card
                    _ProfileHeaderCard(
                      displayName: displayName,
                      email: email,
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
                                                .withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        spreadRadius: 2,
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

                    // Consumo de IA do mês
                    AiQuotaCard(isDark: isDark),
                    const SizedBox(height: AppDimensions.xl),

                    // Detailed account parameters card
                    _ProfileDetailsCard(
                      isDark: isDark,
                      displayName: displayName,
                      email: email,
                    ),
                    const SizedBox(height: AppDimensions.xxl),

                    // Sign Out Action Button
                    AppButton(
                      label: ProfileText.signOut,
                      icon: Icons.logout,
                      isLoading: isSigningOut,
                      variant: AppButtonVariant.secondary,
                      onPressed: onSignOut,
                    ),
                    const SizedBox(height: AppDimensions.sm),

                    // Exigido pela App Store para app com cadastro de conta.
                    const DeleteAccountButton(),
                    const SizedBox(height: 120), // Spacing for navigation bar
                  ],
                );
              },
            ),
          ),
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
    required this.email,
    required this.initial,
    required this.isDark,
  });

  final String displayName;
  final String email;
  final String initial;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecDark
                          : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Session badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'SESSÃO ATIVA',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
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
      ),
    );
  }
}

// ==========================================
// COMPONENT: DETAILED ACCOUNT PARAMETERS
// ==========================================
class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.isDark,
    required this.displayName,
    required this.email,
  });

  final bool isDark;
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProfileText.account,
              style: AppTypography.headingMedium.copyWith(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            _ProfileField(
              label: ProfileText.name,
              value: displayName,
              isDark: isDark,
            ),
            const Divider(height: AppDimensions.xxl),
            _ProfileField(
              label: ProfileText.email,
              value: email,
              isDark: isDark,
            ),
          ],
        ),
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
