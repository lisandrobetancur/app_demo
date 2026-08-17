import 'package:design_system/design_system.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// Teaches the kit what "enabled" means for this app's design system.
///
/// The kit ships the Flutter built-ins and nothing else — it cannot know
/// about `AppButton` without depending on this app, which is exactly what
/// makes it reusable. Each project registers its own widgets once.
///
/// `AppButton` is the reason this exists rather than being a formality: it
/// renders a loading state that swaps the callback for `null` further down
/// (`isLoading ? null : onPressed`), so a button mid-request is inert while
/// still holding its callback. Reading only `onPressed` calls that button
/// enabled — which is what four page objects did before this rule existed.
///
/// Called from [launchMarketApp], so no test has to remember it.
void registerMarketWidgetProbes() {
  WidgetProbes.enabled<AppButton>(
    (AppButton button) => button.onPressed != null && !button.isLoading,
  );
  WidgetProbes.enabled<AppTextField>((AppTextField field) => field.enabled);
}
