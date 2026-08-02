/// SQLite layer of the market workspace.
///
/// Single owner of the connection, the schema, the migrations and the
/// deterministic seed. Features talk to it through [AppDatabase] (DAOs) and
/// never open their own connections.
library;

export 'package:sqflite/sqflite.dart'
    show Batch, ConflictAlgorithm, Database, DatabaseExecutor, Transaction;

export 'src/app_database.dart';
export 'src/base_dao.dart';
export 'src/database_factory_resolver.dart';
export 'src/db_tables.dart';
export 'src/market_database.dart';
export 'src/seed_mode.dart';
