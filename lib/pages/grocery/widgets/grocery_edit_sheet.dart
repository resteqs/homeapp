import 'package:flutter/material.dart';

import 'package:homeapp/models/grocery_item.dart';

class GroceryEditSheet extends StatefulWidget {
  final GroceryItem item;
  final Future<void> Function(GroceryItem item, String newName, int quantity, String? unit)
      onSave;
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
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late int _quantity;

  final DraggableScrollableController _sheetController = DraggableScrollableController();
  final FocusNode _nameNode = FocusNode();
  final FocusNode _quantityNode = FocusNode();
  final FocusNode _unitNode = FocusNode();
  final FocusNode _noteNode = FocusNode();
  final FocusNode _priceNode = FocusNode();

  // Mock fields
  final TextEditingController _noteController = TextEditingController(
      text: "👆 Tippe auf das Element, um es zu bearbeiten");
  final TextEditingController _priceController =
      TextEditingController(text: "0,00 €");

  bool _important = false;
  bool _notAvailable = false;
  bool _onlyOnSale = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantity = widget.item.quantity;
    _quantityController = TextEditingController(
        text: _quantity > 0 ? _quantity.toString() : '');
    _unitController = TextEditingController(text: widget.item.unit ?? '');

    void expandSheet() {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.95,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }

    _nameNode.addListener(() { if (_nameNode.hasFocus) expandSheet(); });
    _quantityNode.addListener(() { if (_quantityNode.hasFocus) expandSheet(); });
    _unitNode.addListener(() { if (_unitNode.hasFocus) expandSheet(); });
    _noteNode.addListener(() { if (_noteNode.hasFocus) expandSheet(); });
    _priceNode.addListener(() { if (_priceNode.hasFocus) expandSheet(); });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    _sheetController.dispose();
    _nameNode.dispose();
    _quantityNode.dispose();
    _unitNode.dispose();
    _noteNode.dispose();
    _priceNode.dispose();
    super.dispose();
  }

  void _save() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    final unitText = _unitController.text.trim();
    widget.onSave(widget.item, newName, _quantity, unitText.isEmpty ? null : unitText).then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colors based on light theme
    const bgColor = Colors.white;
    const surfaceColor = Color(0xFFF2F2F7); // Light gray
    final accentGreen = Theme.of(context).colorScheme.primary; // Green
    const textColor = Colors.black87;
    const secondaryTextColor = Colors.black54;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.50,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          color: bgColor,
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
          ),
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
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Speichern button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _save,
                      child: const Text('Speichern',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // Name input
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
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
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Artikelname',
                              hintStyle: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        ),
                        const Icon(Icons.back_hand,
                            color: Color(0xFF609966),
                            size: 20), // Yellow pointing hand approximation
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantity and Unit
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _quantityController,
                            focusNode: _quantityNode,
                            style: const TextStyle(color: textColor),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Menge',
                              hintStyle: TextStyle(color: secondaryTextColor),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              _quantity = int.tryParse(val) ?? 0;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _unitController,
                            focusNode: _unitNode,
                            style: const TextStyle(color: textColor),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Einheit',
                              hintStyle: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.remove, color: textColor),
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
                          color: accentGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
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
                  const SizedBox(height: 24),

                  // Mehr Optionen
                  const Text(
                    'MEHR OPTIONEN',
                    style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),

                  // Notiz
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Notiz',
                                style: TextStyle(
                                    color: secondaryTextColor, fontSize: 12)),
                            const Spacer(),
                            const Icon(Icons.cancel,
                                color: secondaryTextColor, size: 16),
                          ],
                        ),
                        TextField(
                          controller: _noteController,
                          focusNode: _noteNode,
                          style:
                              const TextStyle(color: textColor, fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.only(top: 4, bottom: 8),
                          ),
                          maxLines: null,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChip('🔥 Wichtig', _important,
                                () => setState(() => _important = !_important)),
                            _buildChip(
                                '❌ Nicht verfügbar',
                                _notAvailable,
                                () => setState(
                                    () => _notAvailable = !_notAvailable)),
                            _buildChip(
                                '💰 Nur im Angebot',
                                _onlyOnSale,
                                () =>
                                    setState(() => _onlyOnSale = !_onlyOnSale)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preis & Gesamt
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Preis',
                                  style: TextStyle(
                                      color: secondaryTextColor, fontSize: 12)),
                              TextField(
                                controller: _priceController,
                                focusNode: _priceNode,
                                style: const TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Gesamt',
                                style: TextStyle(
                                    color: secondaryTextColor, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('-',
                                style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bottom Actions (Delete & Done)
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer, // Light red tinted background
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error),
                          onPressed: () {
                            widget.onDelete(widget.item);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          onPressed: _save,
                          child: const Text('Fertig',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5E5EA) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.black54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
