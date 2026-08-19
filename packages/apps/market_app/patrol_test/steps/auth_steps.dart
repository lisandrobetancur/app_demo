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


  Future<void> submitCredentials({
    required String email,
    required String password,
  }) => step('Ingresa el email: $email y la contraseña: $password', () async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    await _login.submit();
  });


  Future<void> loginAsDemoUser() => step('Ingresa usuario y contraseña correctos', () async {
    await submitCredentials(
      email: TestData.demoEmail,
      password: TestData.demoPassword,
    );
    await _dashboard.waitUntilVisible();
    should(
      seeThat(
        'En el dashboard se saluda por su nombre al usuario que ha iniciado sesión',
        () => _dashboard.greetingText,
        contains(TestData.demoFullName),
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
}
