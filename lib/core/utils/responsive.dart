import 'package:flutter/widgets.dart';

import '../constants/app_constants.dart';
import '../theme/app_dimensions.dart';

class Responsive {
  const Responsive._();

  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  static EdgeInsets contentPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(AppDimensions.xxxl);
    }

    if (isTablet(context)) {
      return const EdgeInsets.all(AppDimensions.xxl);
    }

    return const EdgeInsets.all(AppDimensions.lg);
  }

  static Widget constrainedContent({required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.kContentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
