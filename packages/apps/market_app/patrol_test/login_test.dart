import 'package:patrol/patrol.dart';

import 'steps/steps.dart';
import 'support/support.dart';

/// F04 · Login and session.
///
/// The test body only speaks business language; every locator lives in a page
/// object and every interaction in a step.
void main() {
  patrolTest('logs in with the seeded demo account', (
    PatrolIntegrationTester $,
  ) async {
    await launchMarketApp($);
    final Steps steps = Steps($);

    await steps.auth.loginAsDemoUser();
  });

  patrolTest('rejects wrong credentials without revealing the email', (
    PatrolIntegrationTester $,
  ) async {
    await launchMarketApp($);
    final Steps steps = Steps($);

    await steps.auth.submitCredentials(
      email: TestData.demoEmail,
      password: 'WrongPassword1',
    );

    await steps.auth.expectLoginRejected();
    steps.auth.expectGenericCredentialsError();
  });

  patrolTest('keeps submission blocked while the form is invalid', (
    PatrolIntegrationTester $,
  ) async {
    await launchMarketApp($);
    final Steps steps = Steps($);

    await steps.auth.expectSubmitDisabledFor(
      email: 'not-an-email',
      password: TestData.demoPassword,
    );
  });
}
