import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/route_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_button.dart';
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

    // A home entra primeiro para o cadastro da chave ter para onde voltar.
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
    return Scaffold(
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
                      return _OnboardingPage(page: OnboardingText.pages[index]);
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
                // Cadastrar a chave não pode ser obrigatório: criar e estudar
                // cards à mão funciona sem IA nenhuma, e travar aqui perderia
                // quem só quer isso.
                if (_isLastPage) ...[
                  const SizedBox(height: AppDimensions.sm),
                  AppButton(
                    label: OnboardingText.skipKey,
                    variant: AppButtonVariant.secondary,
                    onPressed: _complete,
                  ),
                ],
                // O aviso aparece na última página, junto do botão que
                // efetivamente registra o aceite — antes disso ninguém leu
                // nada ainda.
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
  const _OnboardingPage({required this.page});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? AppColors.textSecDark
        : AppColors.textSecondary;

    // Rola quando não couber: a altura útil varia muito entre aparelhos, e
    // uma descrição um pouco mais longa não pode cortar o conteúdo.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HeroBadge(icon: page.icon),
                const SizedBox(height: AppDimensions.huge),
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
        );
      },
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      width: AppDimensions.onboardingHeroSize,
      height: AppDimensions.onboardingHeroSize,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radius3Xl),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: AppDimensions.xxxl,
            offset: Offset(0, AppDimensions.lg),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: AppDimensions.huge * 2,
          height: AppDimensions.huge * 2,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppDimensions.radius2Xl),
          ),
          child: Icon(icon, size: AppDimensions.huge, color: AppColors.primary),
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
