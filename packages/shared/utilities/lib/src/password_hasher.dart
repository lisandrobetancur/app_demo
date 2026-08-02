import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Password hashing for the demo.
///
/// Passwords are never stored in plain text: the caller provides a per-user
/// [salt] (generated through the injected `IdGenerator`) and the hash is
/// `sha256(salt + password)`.
///
/// NOTE: in production this would use a cost-based KDF (bcrypt / argon2) and
/// platform secure storage instead of a single SHA-256 round; a plain hash is
/// acceptable only because this is an offline demo with seeded users.
class PasswordHasher {
  const PasswordHasher._();

  /// Hashes [password] with [salt] using SHA-256.
  static String hash({required String password, required String salt}) =>
      sha256.convert(utf8.encode('$salt$password')).toString();

  /// Constant-shape verification helper.
  static bool verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) => hash(password: password, salt: salt) == expectedHash;
}
