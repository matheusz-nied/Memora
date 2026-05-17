import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_state.dart';
import 'auth_repository.dart';
import 'profile_text.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  var _isSigningOut = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(ProfileText.title)),
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: Padding(
            padding: Responsive.contentPadding(context),
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      displayName: user.displayName,
                      email: user.email,
                    ),
                    const SizedBox(height: AppDimensions.xxl),
                    _ProfileInfoCard(
                      displayName: user.displayName,
                      email: user.email,
                      userId: user.id,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppDimensions.lg),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                    const Spacer(),
                    AppButton(
                      label: ProfileText.signOut,
                      icon: Icons.logout,
                      isLoading: _isSigningOut,
                      variant: AppButtonVariant.secondary,
                      onPressed: _signOut,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go(RouteConstants.kRouteLogin);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = ProfileText.signOutError;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.displayName, required this.email});

  final String? displayName;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final title = _fallback(displayName, ProfileText.authenticatedUser);
    final subtitle = _fallback(email, ProfileText.noEmail);

    return Row(
      children: [
        Container(
          width: AppDimensions.huge,
          height: AppDimensions.huge,
          decoration: const BoxDecoration(
            color: AppColors.infoBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_circle_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.displayName,
    required this.email,
    required this.userId,
  });

  final String? displayName;
  final String? email;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ProfileText.account,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppDimensions.lg),
            _ProfileField(
              label: ProfileText.name,
              value: _fallback(displayName, ProfileText.noName),
            ),
            const Divider(height: AppDimensions.xxl),
            _ProfileField(
              label: ProfileText.email,
              value: _fallback(email, ProfileText.noEmail),
            ),
            const Divider(height: AppDimensions.xxl),
            _ProfileField(label: ProfileText.userId, value: userId),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppDimensions.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

String _fallback(String? value, String fallback) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
}
