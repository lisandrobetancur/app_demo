import 'package:typing/typing.dart';
import 'package:uuid/uuid.dart';

/// Default [IdGenerator] backed by UUID v4.
///
/// This is the only place in the workspace where `uuid` is referenced; the
/// shell overrides `idGeneratorProvider` with this implementation. Tests or
/// demos can override it with a sequential generator for full determinism.
class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
