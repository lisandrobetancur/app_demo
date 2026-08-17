/// Test infrastructure for this app.
///
/// Re-exports the reusable kit so a page, a step or a test needs one import.
/// What lives here instead of in the kit is what only this app can answer:
/// how to boot it, what its seeded data is, and what "enabled" means for its
/// design system.
library;

export 'package:patrol_kit/patrol_kit.dart';

export 'app_launcher.dart';
export 'test_data.dart';
export 'widget_probes.dart';
