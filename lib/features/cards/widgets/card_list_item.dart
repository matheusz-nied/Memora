import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../card_model.dart';
import '../card_text.dart';

class CardListItem extends StatelessWidget {
  const CardListItem({
    super.key,
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  final CardModel card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.front,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                PopupMenuButton<_CardAction>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (action) {
                    switch (action) {
                      case _CardAction.edit:
                        onEdit();
                      case _CardAction.delete:
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _CardAction.edit,
                      child: Text(CardText.edit),
                    ),
                    PopupMenuItem(
                      value: _CardAction.delete,
                      child: Text(CardText.delete),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              card.back,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

enum _CardAction { edit, delete }
