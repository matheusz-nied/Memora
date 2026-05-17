import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_dimensions.dart';
import '../generate_text.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GenerateText.quantity,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppDimensions.sm),
        SegmentedButton<int>(
          segments: AppConstants.kCardQuantityOptions
              .map(
                (quantity) => ButtonSegment<int>(
                  value: quantity,
                  label: Text(quantity.toString()),
                ),
              )
              .toList(),
          selected: {value},
          onSelectionChanged: (selected) => onChanged(selected.single),
        ),
      ],
    );
  }
}
