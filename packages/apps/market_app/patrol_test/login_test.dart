import 'package:patrol/patrol.dart';

import 'steps/steps.dart';
import 'support/support.dart';

/// F04 · Login and session.
///
/// The test body only speaks business language; every locator lives in a page
/// object and every interaction in a step.
void main() {
  e2eTest(
    'logs in with the seeded demo account',
    tags: <String>[Tags.smoke, Tags.success],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Access',
        feature: 'Authentication',
        story: 'Sign in with valid credentials',
        severity: Severity.blocker,
        description:
            'Without login there is no cart, no orders and no profile: it is '
            'the door to everything else.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      // `testParam` goes AFTER the launch, not before: it reads from
      // `TestData`, and the data lives in the asset bundle, which does not
      // exist until the app has launched. It also records what the test
      // actually used, rather than what it meant to use.
      testParam('User', TestData.demoEmail);

      await steps.auth.loginAsDemoUser();
    },
  );

  e2eTest(
    'rejects wrong credentials without revealing the email',
    tags: <String>[Tags.smoke, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Access',
        feature: 'Authentication',
        story: 'Reject invalid credentials without leaking whether the email '
            'exists',
        severity: Severity.critical,
        description:
            'The message must stay generic: telling "no such email" apart from '
            '"wrong password" lets an attacker enumerate registered accounts. '
            'The cases come from patrol_test/data/invalid_logins.json.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      // One test, several cases. Walking the rows inside the test rather than
      // generating a test per row is deliberate: the data is read from the
      // asset bundle, which only exists once the app has launched — and
      // `main()` runs before that. They also share a single launch, which is
      // the expensive part of an E2E.
      for (final DataRecord row in TestData.invalidLogins) {
        final String label = row.string('case');
        testParam(label, '${row.string('email')} / ${row.string('password')}');
        Log.info('Invalid case: $label');

        await steps.auth.submitCredentials(
          email: row.string('email'),
          password: row.string('password'),
        );
        await steps.auth.expectLoginRejected();
        await steps.auth.expectGenericCredentialsError();
      }
    },
  );

  e2eTest(
    'keeps submission blocked while the form is invalid',
    tags: <String>[Tags.regression, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Access',
        feature: 'Authentication',
        story: 'Block submission while the form is invalid',
        severity: Severity.normal,
        description:
            'Live validation must stop the submission before it spends a call '
            'on the backend.',
      );
      testParam('Invalid email', 'not-an-email');

      await launchMarketApp($);
      final Steps steps = Steps($);

      await steps.auth.expectSubmitDisabledFor(
        email: 'not-an-email',
        password: TestData.demoPassword,
      );
    },
  );
}
