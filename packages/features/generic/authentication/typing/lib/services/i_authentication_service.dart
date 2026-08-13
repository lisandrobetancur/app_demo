import '../models/auth_user.dart';

/// Authentication contract.
///
/// The implementation owns the `users` table access, password hashing and
/// session persistence; it publishes the active user through
/// `authSessionProvider`.
abstract interface class IAuthenticationService {
  /// Restores a remembered session at boot; returns the user or `null`.
  Future<AuthUser?> restoreSession();

  /// Logs in. Throws `AuthException(invalidCredentials)` on a wrong pair.
  Future<AuthUser> login({
    required String email,
    required String password,
  });

  /// Registers a new user, opens their session and creates the welcome
  /// notification. Throws `AuthException(emailInUse)` on duplicates.
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  });

  /// Clears the session (memory and persistence). Cart and orders remain.
  Future<void> logout();

  /// Starts password recovery: returns the deterministic 6-digit demo code
  /// for [email]. Throws `AuthException(emailNotFound)` for unknown emails.
  Future<String> requestRecoveryCode({required String email});

  /// Completes recovery. Throws `AuthException(invalidCode)` when [code]
  /// does not match the one issued for [email].
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Changes the password of the active user. Throws
  /// `AuthException(wrongPassword)` when [currentPassword] is wrong.
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  });

  /// Re-reads the active user from the database into the session (after a
  /// profile edit).
  Future<void> refreshSession();
}
