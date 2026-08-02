/// Pure contracts shared across the market workspace.
///
/// Contains the base [ViewModel], the injectable [Clock] and [IdGenerator]
/// contracts and cross-cutting enums. This package never exposes widgets.
library;

export 'src/clock.dart';
export 'src/id_generator.dart';
export 'src/view_model.dart';
export 'src/view_status.dart';
