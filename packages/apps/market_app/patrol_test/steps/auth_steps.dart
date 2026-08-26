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
  //
  // The two frames are named here, and they are the two this step is worth:
  // the credentials as they were typed — which the submit is about to replace
  // — and whatever the submit produced, be it the dashboard or an error under
  // the form. Written out rather than left to a policy, because the moment
  // that matters in a step is not one a rule can find.
  Future<void> login({required String email, required String password}) =>
      step('Ingresa el email: $email y la contraseña', () async {
        await _login.fillCredentials(email: email, password: password);
        await capturing(
          _login.submit,
          before: 'Las credenciales digitadas, antes de enviar',
          after: 'Lo que produjo el envío',
        );
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

  Future<void>
  expectLoginRejected() => step('Se rechaza el inicio de sesión', () async {
    should(
      seeThat(
        'Un inicio de sesión fallido deja al usuario en la pantalla de ingreso',
        () => _login.isVisible,
        isTrue,
      ),
      seeThat(
        'Un inicio de sesión fallido no llega al dashboard',
        () => _dashboard.isVisible,
        isFalse,
      ),
    );
  });

  /// Asserts the visible error message — the app never reveals whether the
  /// email exists, so both wrong-email and wrong-password show this one.
  Future<void> expectGenericCredentialsError() =>
      step('Se muestra el error genérico de credenciales', () async {
        should(
          seeThat(
            'Unas credenciales inválidas muestran el error genérico en línea',
            () => _login.hasErrorText('Correo o contraseña incorrectos'),
            isTrue,
          ),
        );
      });

  /// Walks the three onboarding slides and finishes on the last one.
  Future<void> completeOnboarding() => step('Completa el onboarding', () async {
    await _onboarding.waitUntilVisible();
    await _onboarding.next();
    await _onboarding.next();
    await _onboarding.start();
  });

  /// Skips the onboarding from the first slide.
  Future<void> skipOnboarding() => step('Omite el onboarding', () async {
    await _onboarding.waitUntilVisible();
    await _onboarding.skip();
  });

  /// Confirms the submit button stays disabled until the form is valid.
  Future<void> expectSubmitDisabledFor({
    required String email,
    required String password,
  }) => step('Se bloquea el envío para "$email"', () async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    should(
      seeThat(
        'La validación en vivo bloquea el envío para "$email"',
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
  }) => step('Se habilita el envío para "$email"', () async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    should(
      seeThat(
        'La validación en vivo habilita el envío para "$email"',
        () => _login.isSubmitEnabled,
        isTrue,
      ),
    );
  });
}
