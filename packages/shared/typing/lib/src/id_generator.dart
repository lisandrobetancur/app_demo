import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable identifier source.
///
/// Concrete implementations live outside this package (the workspace default
/// wraps `uuid`); the shell overrides [idGeneratorProvider] with one of them.
/// This keeps id generation substitutable and the app deterministic on demand.
abstract interface class IdGenerator {
  /// Returns a new unique identifier.
  String newId();
}

/// Contract provider, overridden by the shell with a real implementation.
final Provider<IdGenerator> idGeneratorProvider = Provider<IdGenerator>(
  (Ref ref) => throw UnimplementedError('idGeneratorProvider'),
);
