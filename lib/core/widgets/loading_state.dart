import 'package:flutter/material.dart';

import '../theme/app_dimensions.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.xxxl),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
