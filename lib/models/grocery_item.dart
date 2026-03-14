class GroceryItem {
  final String id;
  final String listId;
  final String name;
  final String category;
  final bool isBought;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String syncStatus;

  const GroceryItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.category,
    required this.isBought,
    required this.updatedAt,
    required this.deletedAt,
    required this.syncStatus,
  });

  factory GroceryItem.fromMap(Map<String, dynamic> map) {
    return GroceryItem(
      id: map['id']?.toString() ?? '',
      listId: map['list_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      category: map['category']?.toString() ?? 'Other',
      isBought: map['is_bought'] == true || map['is_bought'] == 1,
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      deletedAt: DateTime.tryParse(map['deleted_at']?.toString() ?? ''),
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'name': name,
      'category': category,
      'is_bought': isBought ? 1 : 0,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  GroceryItem copyWith({
    String? id,
    String? listId,
    String? name,
    String? category,
    bool? isBought,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? syncStatus,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      category: category ?? this.category,
      isBought: isBought ?? this.isBought,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
