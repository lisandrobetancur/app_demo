part of com.demo.market.authentication.core;

/// Concrete [IAuthenticationService].
///
/// Owns credential verification, session persistence and the deterministic
/// demo recovery code. Passwords are stored as `sha256(salt + password)`
/// (see [PasswordHasher] for the production caveat).
class AuthenticationService implements IAuthenticationService {
  AuthenticationService({
    required UsersDao dao,
    required Clock clock,
    required IdGenerator idGenerator,
    required INotificationsService notifications,
    required StateController<AuthUser?> session,
  }) : _dao = dao,
       _clock = clock,
       _idGenerator = idGenerator,
       _notifications = notifications,
       _session = session;

  final UsersDao _dao;
  final Clock _clock;
  final IdGenerator _idGenerator;
  final INotificationsService _notifications;
  final StateController<AuthUser?> _session;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<AuthUser?> restoreSession() async {
    final SharedPreferences prefs = await _prefs;
    final String? userId = prefs.getString(
      AuthenticationLimits.sessionUserIdPrefKey,
    );
    if (userId == null) {
      return null;
    }
    final Map<String, Object?>? row = await _dao.findById(userId);
    if (row == null) {
      await prefs.remove(AuthenticationLimits.sessionUserIdPrefKey);
      return null;
    }
    final AuthUser user = AuthUser.fromMap(row);
    _session.state = user;
    return user;
  }

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final Map<String, Object?>? row = await _dao.findByEmail(_normalize(email));
    if (row == null) {
      throw const AuthException(AuthErrorCode.invalidCredentials);
    }
    final bool matches = PasswordHasher.verify(
      password: password,
      salt: row['password_salt']! as String,
      expectedHash: row['password_hash']! as String,
    );
    if (!matches) {
      throw const AuthException(AuthErrorCode.invalidCredentials);
    }
    final AuthUser user = AuthUser.fromMap(row);
    _session.state = user;
    // The session is deliberately not persisted: every launch starts logged
    // out, so writing it would only leave a credential lying in storage that
    // the next bootstrap deletes anyway.
    return user;
  }

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final String normalizedEmail = _normalize(email);
    final Map<String, Object?>? existing = await _dao.findByEmail(
      normalizedEmail,
    );
    if (existing != null) {
      throw const AuthException(AuthErrorCode.emailInUse);
    }
    final String id = _idGenerator.newId();
    final String salt = _idGenerator.newId();
    final DateTime now = _clock();
    await _dao.insert(<String, Object?>{
      'id': id,
      'full_name': fullName.trim(),
      'email': normalizedEmail,
      'phone': phone == null || phone.trim().isEmpty ? null : phone.trim(),
      'avatar_path': null,
      'password_hash': PasswordHasher.hash(password: password, salt: salt),
      'password_salt': salt,
      'created_at': now.millisecondsSinceEpoch,
    });
    await _notifications.create(
      userId: id,
      type: NotificationType.welcome,
      titleKey: 'app_cross.notifications.welcome_title',
      bodyKey: 'app_cross.notifications.welcome_body',
      payload: '{"route":"/dashboard"}',
    );
    final AuthUser user = AuthUser(
      id: id,
      fullName: fullName.trim(),
      email: normalizedEmail,
      createdAt: now,
      phone: phone == null || phone.trim().isEmpty ? null : phone.trim(),
    );
    _session.state = user;
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(AuthenticationLimits.sessionUserIdPrefKey, id);
    return user;
  }

  @override
  Future<void> logout() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(AuthenticationLimits.sessionUserIdPrefKey);
    _session.state = null;
    log.info('Session closed');
  }

  @override
  Future<String> requestRecoveryCode({required String email}) async {
    final Map<String, Object?>? row = await _dao.findByEmail(_normalize(email));
    if (row == null) {
      throw const AuthException(AuthErrorCode.emailNotFound);
    }
    return _recoveryCodeFor(_normalize(email));
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final String normalizedEmail = _normalize(email);
    final Map<String, Object?>? row = await _dao.findByEmail(normalizedEmail);
    if (row == null) {
      throw const AuthException(AuthErrorCode.emailNotFound);
    }
    if (code != _recoveryCodeFor(normalizedEmail)) {
      throw const AuthException(AuthErrorCode.invalidCode);
    }
    final String salt = _idGenerator.newId();
    await _dao.updatePassword(
      userId: row['id']! as String,
      passwordHash: PasswordHasher.hash(password: newPassword, salt: salt),
      passwordSalt: salt,
    );
  }

  @override
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final Map<String, Object?>? row = await _dao.findById(userId);
    if (row == null) {
      throw const AuthException(AuthErrorCode.invalidCredentials);
    }
    final bool matches = PasswordHasher.verify(
      password: currentPassword,
      salt: row['password_salt']! as String,
      expectedHash: row['password_hash']! as String,
    );
    if (!matches) {
      throw const AuthException(AuthErrorCode.wrongPassword);
    }
    final String salt = _idGenerator.newId();
    await _dao.updatePassword(
      userId: userId,
      passwordHash: PasswordHasher.hash(password: newPassword, salt: salt),
      passwordSalt: salt,
    );
  }

  @override
  Future<void> refreshSession() async {
    final AuthUser? current = _session.state;
    if (current == null) {
      return;
    }
    final Map<String, Object?>? row = await _dao.findById(current.id);
    _session.state = row == null ? null : AuthUser.fromMap(row);
  }

  String _normalize(String email) => email.trim().toLowerCase();

  /// Deterministic 6-digit demo code derived from the email. In production
  /// this would be a random, expiring, server-issued code.
  String _recoveryCodeFor(String email) {
    final String digest = PasswordHasher.hash(
      password: email,
      salt: 'recovery',
    );
    final int value = int.parse(digest.substring(0, 8), radix: 16) % 1000000;
    return value.toString().padLeft(
      AuthenticationLimits.recoveryCodeLength,
      '0',
    );
  }
}
