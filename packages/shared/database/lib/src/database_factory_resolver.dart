import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:utilities/utilities.dart';

/// The single place where the SQLite backend is chosen per platform.
///
/// | Platform      | Factory                                          |
/// |---------------|--------------------------------------------------|
/// | Android / iOS | `sqflite` default factory (`getDatabasesPath()`) |
/// | Web           | `sqflite_common_ffi_web` (wasm + IndexedDB)      |
///
/// The web factory needs `sqlite3.wasm` and its worker under the app's
/// `web/` directory (`dart run sqflite_common_ffi_web:setup`).
DatabaseFactory resolveDatabaseFactory() =>
    PlatformGuard.isWeb ? databaseFactoryFfiWeb : databaseFactory;

/// Resolves the database location for the given [factory].
///
/// On the web the "path" is just a logical name inside IndexedDB; on mobile
/// it lives under the platform databases directory.
Future<String> resolveDatabasePath(
  DatabaseFactory factory, {
  required String fileName,
}) async {
  if (PlatformGuard.isWeb) {
    return fileName;
  }
  final String directory = await factory.getDatabasesPath();
  return p.join(directory, fileName);
}
