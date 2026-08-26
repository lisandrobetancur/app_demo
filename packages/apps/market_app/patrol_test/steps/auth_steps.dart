import 'package:flutter_test/flutter_test.dart';

import '../pages/pages.dart';
import '../support/support.dart';

class AuthSteps extends BaseSteps {
  AuthSteps(super.$)
    : _login = LoginPage($),
      _onboarding = OnboardingPage($),
      _dashboard = DashboardPage($);

  final LoginPage _login;
  final OnboardingPage _onboarding;
  final DashboardPage _dashboard;

  // The data arrives as parameters, always: a step performs and asserts, and
  // the TEST decides with which user, which password, which name. A step that
  // reaches into TestData on its own hides half the scenario from the file
  // that claims to define it.
  //
  // The step name carries the email but NEVER the password: step names are
  // published — they go through the marker stream into the HTML report, which
  // CI uploads and GitHub Pages serves. Demo data today, but the day this
  // suite points at a staging login, the wording of this line is the
  // difference between a report and a leak. The obscured field keeps it out
  // of the screenshots; this keeps it out of the text.
  Future<void> login({required String email, required String password}) =>
      step('Ingresa el email: $email y la contraseña', () async {
        await _login.login(email: email, password: password);
      });

  /// Asserts the session actually opened: the dashboard is on screen and
  /// greets [fullName].
  ///
  /// Separate from [login] on purpose — the same submission is followed by
  /// this assertion in one test and by [expectLoginRejected] in another, and
  /// the difference between those two futures is the test's to state, not
  /// the step's to assume.
  Future<void> expectLoggedInAs(
    String fullName,
  ) => step('El dashboard recibe a $fullName', () async {
    await _dashboard.waitUntilVisible();
    should(
      seeThat(
        'En el dashboard se saluda por su nombre al usuario que ha iniciado sesión',
        () => _dashboard.greetingText,
        contains(fullName),
      ),
    );
  });

  Future<void> expectLoginRejected() =>
      step('Expect the login to be rejected', () async {
        should(
          seeThat(
            'a failed login keeps the user on the login screen',
            () => _login.isVisible,
            isTrue,
          ),
          seeThat(
            'a failed login does not reach the dashboard',
            () => _dashboard.isVisible,
            isFalse,
          ),
        );
      });

  /// Asserts the visible error message — the app never reveals whether the
  /// email exists, so both wrong-email and wrong-password show this one.
  Future<void> expectGenericCredentialsError() =>
      step('Expect the generic credentials error', () async {
        should(
          seeThat(
            'invalid credentials show the generic inline error',
            () => _login.hasErrorText('Correo o contraseña incorrectos'),
            isTrue,
          ),
        );
      });

  /// Walks the three onboarding slides and finishes on the last one.
  Future<void> completeOnboarding() =>
      step('Complete the onboarding', () async {
        await _onboarding.waitUntilVisible();
        await _onboarding.next();
        await _onboarding.next();
        await _onboarding.start();
      });

  /// Skips the onboarding from the first slide.
  Future<void> skipOnboarding() => step('Skip the onboarding', () async {
    await _onboarding.waitUntilVisible();
    await _onboarding.skip();
  });

  /// Confirms the submit button stays disabled until the form is valid.
  Future<void> expectSubmitDisabledFor({
    required String email,
    required String password,
  }) => step('Expect submission blocked for "$email"', () async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    should(
      seeThat(
        'live validation blocks submission for "$email"',
        () => _login.isSubmitEnabled,
        isFalse,
      ),
    );
  });

  /// Confirms the submit button comes ALIVE once the form is valid.
  ///
  /// The other half of [expectSubmitDisabledFor], and the half that keeps the
  /// validation test honest: a disabled button is also what a dead app shows
  /// — nothing typed, nothing enabled — so asserting only the blocked side
  /// passes when no input reached the form at all. That exact false green
  /// happened: in a profile build where typing silently went nowhere, the
  /// validation test was the only one to pass. Asserting the button enables
  /// with valid data makes the test distinguish "validation works" from
  /// "nothing arrived".
  Future<void> expectSubmitEnabledFor({
    required String email,
    required String password,
  }) => step('Expect submission unlocked for "$email"', () async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    should(
      seeThat(
        'live validation unlocks submission for "$email"',
        () => _login.isSubmitEnabled,
        isTrue,
      ),
    );
  });
}
