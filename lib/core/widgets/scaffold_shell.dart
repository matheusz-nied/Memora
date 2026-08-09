import 'package:flutter/material.dart';

import 'app_backdrop.dart';

/// Full-screen shell with the animated app backdrop behind content.
class ScaffoldShell extends StatelessWidget {
  const ScaffoldShell({
    super.key,
    required this.isDark,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
  });

  final bool isDark;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: extendBody,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppBackdrop(isDark: isDark),
          body,
        ],
      ),
    );
  }
}
