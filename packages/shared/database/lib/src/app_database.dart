import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

/// Contract every consumer of the local database depends on.
///
/// The shell overrides [databaseProvider] with a `MarketDatabase` once the
/// platform factory has been initialized during splash.
abstract interface class AppDatabase {
  /// Open (lazily) and return the SQLite database.
  Future<Database> get db;

  /// Deletes everything and re-creates the deterministic seed content.
  Future<void> resetToSeed();

  /// Deletes everything and leaves the database empty.
  Future<void> wipe();

  /// Closes the underlying connection.
  Future<void> close();
}

/// Contract provider, overridden by the shell after bootstrap.
final Provider<AppDatabase> databaseProvider = Provider<AppDatabase>(
  (Ref ref) => throw UnimplementedError('databaseProvider'),
);
