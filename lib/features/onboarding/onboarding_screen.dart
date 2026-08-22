import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/scaffold_shell.dart';
import '../legal/legal_links.dart';
import 'onboarding_page_model.dart';
import 'onboarding_state.dart';
import 'widgets/onboarding_chrome.dart';
import 'widgets/onboarding_page_content.dart';

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
      duration: AppDimensions.animNormal,
      curve: Curves.easeOutCubic,
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
                OnboardingTopBar(
                  showSkip: !_isLastPage,
                  isDark: isDark,
                  onSkip: _complete,
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
                      return OnboardingPageContent(
                        page: OnboardingText.pages[index],
                        isDark: isDark,
                        showBrand: index == 0,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
                OnboardingPageIndicators(
                  count: OnboardingText.pages.length,
                  activeIndex: _pageIndex,
                  isDark: isDark,
                ),
                const SizedBox(height: AppDimensions.xxl),
                OnboardingFooter(
                  isLastPage: _isLastPage,
                  isDark: isDark,
                  onPrimary: _next,
                  onSkipKey: _complete,
                  onOpenPolicy: () => LegalLinks.openPrivacyPolicy(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
