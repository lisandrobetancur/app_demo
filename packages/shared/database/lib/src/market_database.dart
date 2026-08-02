import 'package:sqflite/sqflite.dart';
import 'package:utilities/utilities.dart';

import 'app_database.dart';
import 'database_factory_resolver.dart';
import 'db_tables.dart';
import 'schema.dart';
import 'seed.dart';
import 'seed_mode.dart';

/// Concrete [AppDatabase] used by the app on every platform.
///
/// The connection is opened lazily; `onCreate` builds the v1 schema and, in
/// [SeedMode.demo], applies the deterministic seed. All multi-table writes in
/// the app run inside transactions on the [db] this class exposes.
class MarketDatabase implements AppDatabase {
  MarketDatabase({required SeedMode seedMode, String fileName = 'market.db'})
    : _seedMode = seedMode,
      _fileName = fileName;

  final SeedMode _seedMode;
  final String _fileName;

  Database? _database;

  @override
  Future<Database> get db async => _database ??= await _open();

  Future<Database> _open() async {
    final DatabaseFactory factory = resolveDatabaseFactory();
    final String path = await resolveDatabasePath(factory, fileName: _fileName);
    log.info('Opening database at $path (seed mode: ${_seedMode.name})');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: Schema.version,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onConfigure(Database database) =>
      database.execute('PRAGMA foreign_keys = ON');

  Future<void> _onCreate(Database database, int version) async {
    for (final String statement in Schema.createStatements) {
      await database.execute(statement);
    }
    if (_seedMode.isDemo) {
      await database.transaction((Transaction txn) => Seed.apply(txn));
    }
  }

  /// Migration dispatcher. The schema is at v1 today, but the mechanism is
  /// in place: every future version adds one `case` that upgrades from the
  /// previous one, and the loop applies them sequentially.
  Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      switch (version) {
        // case 2:
        //   await database.execute('ALTER TABLE ...');
        default:
          log.warning('No migration registered for schema version $version');
      }
    }
  }

  @override
  Future<void> resetToSeed() async {
    final Database database = await db;
    await database.transaction((Transaction txn) async {
      await _deleteAllRows(txn);
      await Seed.apply(txn);
    });
    log.info('Database reset to seed content');
  }

  @override
  Future<void> wipe() async {
    final Database database = await db;
    await database.transaction(_deleteAllRows);
    log.info('Database wiped');
  }

  Future<void> _deleteAllRows(Transaction txn) async {
    for (final String table in DbTables.deletionOrder) {
      await txn.delete(table);
    }
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
