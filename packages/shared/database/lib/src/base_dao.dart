import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Base class for every DAO in the workspace.
///
/// DAOs speak raw SQL and return `Map<String, Object?>` rows; converting rows
/// into models is the service layer's job. No DAO is ever reached from a view
/// or a controller directly.
abstract class BaseDao {
  const BaseDao(this.database);

  final AppDatabase database;

  /// The open database connection.
  Future<Database> get db => database.db;
}
