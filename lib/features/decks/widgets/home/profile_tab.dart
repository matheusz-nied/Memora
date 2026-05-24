import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../auth/auth_repository.dart';
import '../../../auth/profile_text.dart';

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

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      isDark: isDark,
                      displayName: displayName,
                      email: email,
                    ),
                    const SizedBox(height: AppDimensions.xxl),
                    _ProfileDetailsCard(
                      isDark: isDark,
                      displayName: displayName,
                      email: email,
                      userId: user.id,
                    ),
                    const SizedBox(height: AppDimensions.xxl),
                    AppButton(
                      label: ProfileText.signOut,
                      icon: Icons.logout,
                      isLoading: isSigningOut,
                      variant: AppButtonVariant.secondary,
                      onPressed: onSignOut,
                    ),
                    const SizedBox(height: 120),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isDark,
    required this.displayName,
    required this.email,
  });

  final bool isDark;
  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.infoBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(width: AppDimensions.lg),
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
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.textSecDark
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    required this.isDark,
    required this.displayName,
    required this.email,
    required this.userId,
  });

  final bool isDark;
  final String displayName;
  final String email;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.05)
              : AppColors.textPrimary.withValues(alpha: 0.05),
        ),
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      elevation: 0,
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
            const SizedBox(height: AppDimensions.lg),
            _ProfileField(ProfileText.name, displayName, isDark),
            const Divider(height: AppDimensions.xxl),
            _ProfileField(ProfileText.email, email, isDark),
            const Divider(height: AppDimensions.xxl),
            _ProfileField(ProfileText.userId, userId, isDark),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField(this.label, this.value, this.isDark);

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
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
