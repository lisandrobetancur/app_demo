import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable time source.
///
/// Nothing outside this provider is allowed to call [DateTime.now] directly:
/// every service or controller that needs the current time reads
/// [clockProvider] instead, so tests and demos can freeze time.
typedef Clock = DateTime Function();

/// The only sanctioned place in the whole workspace where [DateTime.now]
/// is referenced. Override in tests or demos to freeze time.
final Provider<Clock> clockProvider = Provider<Clock>(
  (Ref ref) => DateTime.now,
);
