# Grocery Architecture

This document explains how the grocery feature is structured and why the
current implementation favors local-first operations.

## Goals

- Fast UI interactions even with poor/no connectivity
- Predictable sync behavior without duplicated writes
- Reduced backend load by batching and debouncing network operations
- Easy extension for recommendation and analytics features

## Main Components

- `lib/data/grocery_repository.dart`: source of truth for grocery UI state and sync orchestration.
- `lib/data/local_grocery_store.dart`: SQLite access layer for local items and metadata.
- `lib/models/grocery_item.dart`: domain model used in memory, local DB mapping, and remote payload mapping.
- `lib/pages/grocery/grocery_detailed_list.dart`: detailed list screen (grouped list, item interactions, add-product entry).
- `lib/pages/grocery/widgets/grocery_add_product_sheet.dart`: add/search product sheet with offline filtering.
- `lib/data/grocery_catalog.dart`: generated offline product catalog and lookup maps.

## Data Flow

### 1) Initialization

1. `GroceryRepository.init()` calls backend bootstrap RPC to ensure household and
   default grocery list exist.
2. Active list id is stored in local meta table.
3. Local cache is loaded first (`refreshFromLocal()`), so UI has immediate data.
4. Background sync starts to reconcile with server.

### 2) User Mutations (Add/Toggle/Delete/Edit/Move)

All mutations follow local-first write semantics:

1. Update row in SQLite with `sync_status` set to a pending state.
2. Mirror update in in-memory `_items` list.
3. Notify listeners so UI updates immediately.
4. Schedule debounced sync to send batched changes to Supabase.

### 3) Sync Pipeline

`sync()` processes in this order:

1. Pending upserts -> Supabase upsert in batch.
2. Pending deletes -> Supabase delete in batch.
3. Optional remote pull (cooldown-based unless forced).
4. Merge remote rows into local SQLite and refresh memory list.

This keeps network usage lower during bursty interactions while still converging
quickly.

## Category Resolution Strategy

When adding or renaming items:

1. Fast fallback category is derived locally from keyword heuristics.
2. Background resolver tries exact local catalog mapping first.
3. If there is no exact local match, the heuristic fallback category is kept.
4. Refined category values are written back locally and synced.

This keeps category resolution deterministic and removes any dependency on a
remote product taxonomy table.

## Offline Product Search

`GroceryAddProductSheet` searches fully offline:

- Empty input: shows curated base recommendations.
- With input: filters full local catalog by substring.
- Existing items are highlighted via a lowercased set for O(1) checks.

No live backend calls are required per keystroke.

## Generated Catalog Maintenance

`generate_dart_catalog.py` parses `generate_groceries.py` and emits:

- `groceryCatalog` (locale -> item names)
- `groceryCategoryKeyByNameLowerEn`
- `groceryCategoryKeyByNameLowerDe`

The generated catalog is the app's source of truth for product suggestions and
exact-name category resolution.

Regenerate whenever source product data changes:

```bash
python3 generate_dart_catalog.py
```

## Performance Considerations

- Debounced sync reduces request frequency in interaction bursts.
- Local cache avoids full-list network pulls on every mutation.
- In-memory item updates avoid unnecessary DB reads after each write.
- O(1) membership checks in add-product sheet prevent per-row linear scans.

## Extension Points

- Add ranking logic for suggestions (e.g., frequency/recency per household).
- Add telemetry around sync duration and pending queue size.
- Add stale-category reconciliation jobs if product taxonomy evolves.
- Add pagination/virtualization if grocery lists become very large.
