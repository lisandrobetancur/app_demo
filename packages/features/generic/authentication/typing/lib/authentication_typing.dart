/// Public contract of the authentication feature.
///
/// Other features depend on this package (never on the module) to read the
/// active session, react to it, or trigger auth flows by route.
library;

export 'package:authentication_constants/authentication_routes.dart';

export 'models/auth_exception.dart';
export 'models/auth_user.dart';
export 'provider/provider.dart';
export 'services/i_authentication_service.dart';
