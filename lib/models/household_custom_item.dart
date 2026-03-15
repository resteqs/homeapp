/// Represents a household-level custom grocery item suggestion.
///
/// These items are cached locally for offline search and synced in batches so
/// product search never needs to hit the backend.
class HouseholdCustomItem {
  const HouseholdCustomItem({
    required this.id,
    required this.householdId,
    required this.name,
    required this.category,
    required this.syncStatus,
  });

  final String id;
  final String householdId;
  final String name;
  final String category;
  final String syncStatus;

  factory HouseholdCustomItem.fromMap(Map<String, dynamic> map) {
    return HouseholdCustomItem(
      id: map['id']?.toString() ?? '',
      householdId: map['household_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? 'Other',
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'household_id': householdId,
      'name': name,
      'category': category,
      'sync_status': syncStatus,
    };
  }

  HouseholdCustomItem copyWith({
    String? id,
    String? householdId,
    String? name,
    String? category,
    String? syncStatus,
  }) {
    return HouseholdCustomItem(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      category: category ?? this.category,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}