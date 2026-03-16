import 'package:flutter/material.dart';
import 'package:homeapp/models/grocery_item.dart';
import 'package:homeapp/utils/category_utils.dart';

/// Bottom sheet for editing one grocery item and optional metadata fields.
class GroceryEditSheet extends StatefulWidget {
  final GroceryItem item;
  final Future<void> Function(
    GroceryItem item,
    String newName,
    int quantity,
    String? unit,
    String? notes,
    String? badgeEmoji,
  ) onSave;
  final Future<void> Function(GroceryItem item) onDelete;

  const GroceryEditSheet({
    super.key,
    required this.item,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<GroceryEditSheet> createState() => _GroceryEditSheetState();
}

class _GroceryEditSheetState extends State<GroceryEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _notesController;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final FocusNode _nameNode = FocusNode();
  final FocusNode _quantityNode = FocusNode();
  final FocusNode _unitNode = FocusNode();
  final FocusNode _notesNode = FocusNode();

  late int _quantity;
  String? _selectedBadgeEmoji;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantity = widget.item.quantity > 0 ? widget.item.quantity : 1;
    _quantityController = TextEditingController(text: _quantity.toString());
    _unitController = TextEditingController(text: widget.item.unit ?? '');
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _selectedBadgeEmoji = widget.item.badgeEmoji;

    void expandSheet() {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.95,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    }

    _nameNode.addListener(() {
      if (_nameNode.hasFocus) expandSheet();
    });
    _quantityNode.addListener(() {
      if (_quantityNode.hasFocus) expandSheet();
    });
    _unitNode.addListener(() {
      if (_unitNode.hasFocus) expandSheet();
    });
    _notesNode.addListener(() {
      if (_notesNode.hasFocus) expandSheet();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _notesController.dispose();
    _sheetController.dispose();
    _nameNode.dispose();
    _quantityNode.dispose();
    _unitNode.dispose();
    _notesNode.dispose();
    super.dispose();
  }

  void _onHeaderVerticalDrag(DragUpdateDetails details) {
    if (!_sheetController.isAttached) return;
    final delta = details.primaryDelta ?? 0;
    final viewportHeight = MediaQuery.of(context).size.height;
    final nextSize =
        (_sheetController.size - (delta / viewportHeight)).clamp(0.45, 0.95);
    _sheetController.jumpTo(nextSize);
  }

  void _toggleBadge(String emoji) {
    setState(() {
      _selectedBadgeEmoji = _selectedBadgeEmoji == emoji ? null : emoji;
    });
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final parsedQuantity = int.tryParse(_quantityController.text.trim());
    final safeQuantity = parsedQuantity == null || parsedQuantity < 1
        ? 1
        : parsedQuantity;
    final unitText = _unitController.text.trim();
    final notesText = _notesController.text.trim();

    await widget.onSave(
      widget.item,
      newName,
      safeQuantity,
      unitText.isEmpty ? null : unitText,
      notesText.isEmpty ? null : notesText,
      _selectedBadgeEmoji,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBadgeChip(String emoji, String label) {
    final selected = _selectedBadgeEmoji == emoji;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => _toggleBadge(emoji),
      label: Text('$emoji $label'),
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide(
        color: selected ? Colors.transparent : colorScheme.outlineVariant,
      ),
      labelStyle: TextStyle(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryKey = CategoryUtils.categoryKeyFromRaw(widget.item.category);
    final categoryName = CategoryUtils.localizedCategoryName(context, categoryKey);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.62,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: _onHeaderVerticalDrag,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            focusNode: _nameNode,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Item name',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          categoryName,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _quantityController,
                            focusNode: _quantityNode,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Qty',
                            ),
                            onChanged: (value) {
                              setState(() {
                                final parsed = int.tryParse(value);
                                _quantity = parsed == null || parsed < 1 ? 1 : parsed;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _unitController,
                            focusNode: _unitNode,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Unit',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() {
                                    _quantity--;
                                    _quantityController.text = _quantity.toString();
                                  });
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: colorScheme.onPrimary),
                          onPressed: () {
                            setState(() {
                              _quantity++;
                              _quantityController.text = _quantity.toString();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'NOTES',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _notesController,
                          focusNode: _notesNode,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'Add a note for this item',
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBadgeChip('🔥', 'Wichtig'),
                            _buildBadgeChip('❌', 'Nicht verfugbar'),
                            _buildBadgeChip('💰', 'Nur im Angebot'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: colorScheme.error),
                          onPressed: () {
                            widget.onDelete(widget.item);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          onPressed: _save,
                          child: const Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
