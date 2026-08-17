import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/scaffold_shell.dart';
import '../legal/legal_links.dart';
import '../legal/legal_text.dart';
import 'onboarding_page_model.dart';
import 'onboarding_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _pageIndex = 0;

  bool get _isLastPage => _pageIndex == OnboardingText.pages.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete({bool openApiKey = false}) async {
    await ref.read(onboardingControllerProvider).complete();
    if (!mounted) {
      return;
    }

    context.go(RouteConstants.kRouteHome);
    if (openApiKey) {
      context.push(RouteConstants.kRouteApiKey);
    }
  }

  Future<void> _next() async {
    if (_isLastPage) {
      await _complete(openApiKey: true);
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaffoldShell(
      isDark: isDark,
      body: SafeArea(
        child: Responsive.constrainedContent(
          child: Padding(
            padding: Responsive.contentPadding(context),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Visibility(
                    visible: !_isLastPage,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: _complete,
                      child: Text(
                        OnboardingText.skip,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: OnboardingText.pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        page: OnboardingText.pages[index],
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.xxl),
                _PageIndicators(
                  count: OnboardingText.pages.length,
                  activeIndex: _pageIndex,
                ),
                const SizedBox(height: AppDimensions.xxl),
                AppButton(
                  label: _isLastPage
                      ? OnboardingText.setupKey
                      : OnboardingText.next,
                  icon: _isLastPage ? Icons.key : Icons.arrow_forward,
                  onPressed: _next,
                ),
                if (_isLastPage) ...[
                  const SizedBox(height: AppDimensions.sm),
                  AppButton(
                    label: OnboardingText.skipKey,
                    variant: AppButtonVariant.secondary,
                    onPressed: _complete,
                  ),
                ],
                if (_isLastPage) ...[
                  const SizedBox(height: AppDimensions.lg),
                  Text(
                    LegalText.consent,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => LegalLinks.openPrivacyPolicy(context),
                    child: const Text(LegalText.openPolicy),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page, required this.isDark});

  final OnboardingPageModel page;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor = isDark
        ? AppColors.textSecDark
        : AppColors.textSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeroBadge(icon: page.icon, isDark: isDark),
                const SizedBox(height: AppDimensions.huge),
                GlassPanel(
                  isDark: isDark,
                  showGlow: false,
                  showTopHighlight: false,
                  borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xxl,
                    vertical: AppDimensions.xxxl,
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Text(
                        page.title,
                        style: theme.textTheme.displayLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      Text(
                        page.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.isDark});

  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      isDark: isDark,
      showGlow: false,
      showTopHighlight: true,
      borderRadius: BorderRadius.circular(AppDimensions.radius3Xl),
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: AppDimensions.onboardingHeroSize,
        height: AppDimensions.onboardingHeroSize,
        child: Center(
          child: Container(
            width: AppDimensions.huge * 2,
            height: AppDimensions.huge * 2,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: isDark ? 0.2 : 1),
              borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              icon,
              size: AppDimensions.huge,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? AppDimensions.xxl : AppDimensions.sm,
          height: AppDimensions.sm,
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        );
      }),
    );
  }
}
