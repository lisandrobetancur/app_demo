import 'package:authentication_constants/authentication_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../pages/pages.dart';
import '../support/support.dart';

/// TEMPORARY PROBE — delete after the profile experiment.
///
/// One question, nothing else: **does a tap reach the app?** In `--profile`
/// the suite fails with empty text fields — `enterText` goes through a test
/// keyboard mock that is not registered there, so the text is silently
/// discarded. Whether *taps* share that fate is unknown, because the only tap
/// observed so far landed on a button the empty form kept disabled.
///
/// So this taps the one thing on the login screen that needs no typed text —
/// the link to the register screen — and asserts the navigation happened.
/// Run it twice:
///
///   bash packages/e2e_framework/tool/e2e/run_web.sh --tags=probe             # debug: control, must pass
///   bash packages/e2e_framework/tool/e2e/run_web.sh --tags=probe --profile   # the question
///
/// probe passes in profile → taps arrive; only typing is broken.
/// probe fails in profile  → nothing interactive arrives; profile is out.
/// probe fails in debug    → the probe itself is wrong; the run says nothing.
void main() {
  e2eTest(
    'SONDA: un tap navega del login al registro',
    tags: <String>['probe'],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.trivial,
        description:
            'Sonda temporal: comprueba que un tap llega a la app tocando el '
            'enlace de registro, sin escribir ningún texto.',
      );

      await launchMarketApp($);
      final LoginPage login = LoginPage($);

      await login.waitUntilVisible();
      await login.openRegister();

      // The register view's own key, straight from the feature's constants: the
      // probe asserts the *navigation*, not any content of the destination.
      await Loc.widgetKey(RegisterKeys.view).resolve($).waitUntilVisible();
      expect(login.isVisible, isFalse);
    },
  );
}
