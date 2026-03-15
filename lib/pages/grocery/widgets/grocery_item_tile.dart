import 'package:flutter/material.dart';
import 'package:homeapp/globals/themes.dart';
import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/utils/category_utils.dart';

/// Row widget for a grocery item with toggle, swipe edit/delete, and metadata.
class GroceryItemTile extends StatelessWidget {
  final GroceryItem item;
  final bool isBought;
  final bool isSelected;
  final bool selectionMode;
  final ValueChanged<GroceryItem> onToggle;
  final ValueChanged<GroceryItem> onDelete;
  final ValueChanged<GroceryItem> onLongPress;
  final ValueChanged<GroceryItem> onTap;

  const GroceryItemTile({
    super.key,
    required this.item,
    required this.isBought,
    required this.isSelected,
    required this.selectionMode,
    required this.onToggle,
    required this.onDelete,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryKey = CategoryUtils.categoryKeyFromRaw(item.category);
    final categoryVisual = CategoryUtils.getCategoryVisual(categoryKey);

    return Dismissible(
      key: ValueKey('grocery-item-${item.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.edit,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onTap(item);
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(item),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.55)
              : Theme.of(context).colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: GestureDetector(
            onTap: () => onToggle(item),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isBought
                    ? Theme.of(context).colorScheme.primary
                    : AppColors.transparent,
                border: Border.all(
                  color: isBought
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isBought
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: isBought ? FontWeight.w400 : FontWeight.w500,
              fontSize: 16,
              decoration:
                  isBought ? TextDecoration.lineThrough : TextDecoration.none,
              color: isBought ? Theme.of(context).colorScheme.outline : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.quantity > 1 ||
                  (item.unit != null && item.unit!.trim().isNotEmpty))
                Text(
                  '${item.quantity}${item.unit != null && item.unit!.trim().isNotEmpty ? ' ${item.unit}' : ''}',
                  style: TextStyle(
                    color: isBought
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (item.quantity > 1 ||
                  (item.unit != null && item.unit!.trim().isNotEmpty))
                const SizedBox(width: 12),
              CircleAvatar(
                radius: 14,
                backgroundColor: isBought
                    ? Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5)
                    : categoryVisual.color.withValues(alpha: 0.15),
                child: Icon(
                  categoryVisual.icon,
                  size: 16,
                  color: isBought
                      ? Theme.of(context).colorScheme.outline
                      : categoryVisual.color,
                ),
              ),
            ],
          ),
          onLongPress: () => onLongPress(item),
          onTap: () => onTap(item),
        ),
      ),
    );
  }
}
