import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../deck_model.dart';
import '../deck_text.dart';

class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.deck,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DeckModel deck;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
                      deck.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  PopupMenuButton<_DeckAction>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (action) {
                      switch (action) {
                        case _DeckAction.edit:
                          onEdit();
                        case _DeckAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _DeckAction.edit,
                        child: Text(DeckText.edit),
                      ),
                      PopupMenuItem(
                        value: _DeckAction.delete,
                        child: Text(DeckText.delete),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                deck.description ?? DeckText.noDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              const SizedBox(height: AppDimensions.xxl),
              Row(
                children: [
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DeckAction { edit, delete }
