import 'package:patrol_kit/patrol_kit.dart';

/// The epics this product is made of.
///
/// One line per epic, and this file is the only place any of them is spelled
/// out. A scenario names the value, never the string, so a rename here reaches
/// every test and the report at once — and a misspelling stops compiling
/// instead of quietly opening a second row in the report.
///
/// The wording is what a reader sees on the Features page, so it is written
/// for them rather than for the code: full words, the product's own language.
abstract final class Epics {
  /// Getting into the product and staying in: sign-in, sessions, the account
  /// itself. Everything else is behind it.
  static const Epic access = Epic('Autenticación y Gestión de Usuarios');

  /// Finding something and paying for it — the path the business lives on.
  static const Epic purchase = Epic('Purchase');
}
