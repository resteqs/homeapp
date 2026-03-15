# homeapp

Home management app built with Flutter, with an offline-first grocery module
that syncs local SQLite changes to Supabase.

## Tech Stack

- Flutter / Dart
- Supabase (Auth + Postgres)
- SQLite via `sqflite` for local cache and offline mode
- Flutter localization (`l10n`) for English/German UI

## Project Structure

- `lib/main.dart`: app entry point
- `lib/data/`: repository + local database helpers
- `lib/models/`: data models used by UI/data layers
- `lib/pages/`: screens and screen-specific widgets
- `lib/l10n/`: localization source and generated classes
- `generate_groceries.py`: source product dataset for SQL seed generation
- `generate_dart_catalog.py`: generator for offline Dart product catalog

## Grocery Module Architecture

The grocery flow uses an offline-first approach:

1. UI mutation (add/toggle/delete/edit/move) updates local SQLite first.
2. UI updates immediately from in-memory repository state.
3. Repository marks rows with `sync_status` and schedules batched sync.
4. Debounced sync pushes pending upserts/deletes to Supabase.
5. Remote data is merged into local DB and reflected back in UI.

Key files:

- `lib/data/grocery_repository.dart`
- `lib/data/local_grocery_store.dart`
- `lib/pages/grocery/grocery_detailed_list.dart`
- `lib/pages/grocery/widgets/grocery_add_product_sheet.dart`

For a detailed walkthrough, see `docs/grocery-architecture.md`.

## Local Product Catalog

The app ships with an offline catalog of products in:

- `lib/data/grocery_catalog.dart` (generated)

Generated from:

- `generate_groceries.py`
- `generate_dart_catalog.py`

Regenerate after changing the product source data:

```bash
python3 generate_dart_catalog.py
```

## Run Locally

1. Install Flutter SDK and dependencies.
2. Fetch packages:

```bash
flutter pub get
```

3. Run app:

```bash
flutter run
```

## Quality Checks

```bash
flutter analyze
dart format lib
```

## Notes For Contributors

- Prefer local-first writes in grocery features.
- Avoid direct UI-triggered network writes in tight interaction loops.
- Keep generated files deterministic and update generator script comments/docs
	when format changes.
