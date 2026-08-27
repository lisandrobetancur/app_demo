/// Reusable Patrol E2E scaffolding.
///
/// Everything here is app-agnostic: it depends on Flutter and Patrol and on
/// nothing else. What a project supplies is its own launcher, its own page
/// objects, its own steps and its own data — plus one registration of what
/// "enabled" means for its widgets, through [WidgetProbes].
///
/// The layers, and what each is forbidden from doing:
///
///  * **Pages** ([BasePage]) know *where* things are ([Loc]) and how to touch
///    them ([UiElement]). They may read a value; they never judge one.
///  * **Steps** ([BaseSteps]) speak business language, assert through
///    [should], and delimit what the report shows. They never hold a locator.
///  * **Tests** call steps and declare metadata ([scenario], [testParam]).
///    They hold neither locators nor assertions.
///
/// The report is built from markers printed to stdout while the suite runs;
/// `packages/e2e_framework/e2e_test_reporter` turns them into a report. Nothing
/// here writes files or talks to the network.
library;

export 'src/assert_d.dart';
export 'src/assert_report.dart';
export 'src/base_page.dart';
export 'src/base_steps.dart';
export 'src/consequence.dart';
export 'src/element.dart';
export 'src/failure_report.dart';
export 'src/locator.dart';
export 'src/log.dart';
export 'src/money.dart';
export 'src/scenario.dart';
export 'src/screenshot.dart';
export 'src/tags.dart';
export 'src/taxonomy.dart';
export 'src/test_data.dart';
export 'src/widget_probes.dart';
