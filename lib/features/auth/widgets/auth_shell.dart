import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/responsive.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.centerHeader = false,
    this.constrainForm = false,
    this.showBackButton = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool centerHeader;
  final bool constrainForm;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? AppColors.textSecDark
        : AppColors.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.authMaxWidth,
            ),
            child: Padding(
              padding: Responsive.contentPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: AppDimensions.huge,
                    child: showBackButton
                        ? IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              }
                            },
                            icon: const Icon(Icons.arrow_back),
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).backButtonTooltip,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: centerHeader
                              ? CrossAxisAlignment.center
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.displayLarge,
                              textAlign: centerHeader
                                  ? TextAlign.center
                                  : TextAlign.start,
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: secondaryTextColor),
                              textAlign: centerHeader
                                  ? TextAlign.center
                                  : TextAlign.start,
                            ),
                            const SizedBox(height: AppDimensions.xxxl),
                            if (constrainForm)
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: AppDimensions.authFormMaxWidth,
                                  ),
                                  child: child,
                                ),
                              )
                            else
                              child,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (footer != null) footer!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
