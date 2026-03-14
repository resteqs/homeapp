import 'package:flutter/material.dart';
import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/utils/category_utils.dart';

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
      child: Card(
        margin: const EdgeInsets.only(bottom: 4),
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55)
            : Theme.of(context).colorScheme.surface,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Checkbox(
            value: item.isBought,
            onChanged: (_) => onToggle(item),
            shape: const CircleBorder(),
            activeColor: Colors.blueAccent,
          ),
          title: Text(
            item.name,
            style: TextStyle(
              fontWeight: isBought ? FontWeight.w400 : FontWeight.w500,
              fontSize: 16,
              decoration: isBought ? TextDecoration.lineThrough : TextDecoration.none,
              color: isBought ? Theme.of(context).colorScheme.outline : null,
            ),
          ),
          subtitle: Text(
            CategoryUtils.localizedCategoryName(context, categoryKey),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${item.quantity}',
                  style: TextStyle(
                    color: isBought
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  categoryVisual.icon,
                  size: 18,
                  color: isBought
                      ? Theme.of(context).colorScheme.outline
                      : categoryVisual.color,
                ),
              ],
            ),
          ),
          onLongPress: () => onLongPress(item),
          onTap: () => onTap(item),
        ),
      ),
    );
  }
}
