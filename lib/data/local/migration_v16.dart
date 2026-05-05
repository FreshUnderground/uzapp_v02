import 'package:drift/drift.dart';

/// Migration from v15 to v16: Add trust & verification fields
///
/// **IMPORTANT**: This migration must be integrated into `uza_database.dart`.
///
/// 1. Add these columns to the `Shops` table class:
///    ```dart
///    IntColumn get responseTimeMinutes => integer().nullable()();
///    ```
///
/// 2. Add these columns to the `Products` table class:
///    ```dart
///    TextColumn get condition => text().withDefault(const Constant('new'))();
///    IntColumn get reportCount => integer().withDefault(const Constant(0))();
///    ```
///
/// 3. Increment `schemaVersion` from 15 to 16
///
/// 4. Add the migration block in `onUpgrade`:
///    ```dart
///    if (from < 16) {
///      await m.addColumn(shops, shops.responseTimeMinutes);
///      await m.addColumn(products, products.condition);
///      await m.addColumn(products, products.reportCount);
///    }
///    ```
///
/// Note: `isVerified` already exists on Shops (added at v11), so no need to add it again.

/// Executes the v15→v16 migration using raw SQL.
/// Can be called directly from the `onUpgrade` callback if preferred.
Future<void> migrateV15ToV16(Migrator m) async {
  // Add response_time_minutes to shops
  await m.database.customStatement(
    'ALTER TABLE shops ADD COLUMN response_time_minutes INTEGER',
  );

  // Add condition to products
  await m.database.customStatement(
    "ALTER TABLE products ADD COLUMN condition TEXT NOT NULL DEFAULT 'new'",
  );

  // Add report_count to products
  await m.database.customStatement(
    'ALTER TABLE products ADD COLUMN report_count INTEGER NOT NULL DEFAULT 0',
  );
}
