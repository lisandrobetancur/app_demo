import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_user.dart';
import '../services/i_authentication_service.dart';

/// Authentication contract provider; the module overrides it.
final Provider<IAuthenticationService> authenticationServiceProvider =
    Provider<IAuthenticationService>(
      (Ref ref) => throw UnimplementedError('authenticationServiceProvider'),
    );

/// Active session, `null` when logged out.
///
/// Owned by the authentication service; the router redirect and every
/// feature that needs the current user watch this provider.
final StateProvider<AuthUser?> authSessionProvider = StateProvider<AuthUser?>(
  (Ref ref) => null,
);
