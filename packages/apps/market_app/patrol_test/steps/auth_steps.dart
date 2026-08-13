import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../pages/pages.dart';
import '../support/support.dart';

/// Business steps around authentication and session.
///
/// The contract of this layer:
///
///  * a step reads like something a person does ("log in as the demo user"),
///    not like a sequence of taps;
///  * a step may compose several pages and may assert the outcome it
///    promises, so a test does not have to;
///  * a step never contains a locator — those live in the page objects.
class AuthSteps {
  AuthSteps(this.$)
    : _login = LoginPage($),
      _onboarding = OnboardingPage($),
      _dashboard = DashboardPage($);

  final PatrolIntegrationTester $;
  final LoginPage _login;
  final OnboardingPage _onboarding;
  final DashboardPage _dashboard;

  /// Fills the form and submits, without asserting the outcome — used by both
  /// the happy path and the failure cases.
  Future<void> submitCredentials({
    required String email,
    required String password,
  }) async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    await _login.submit();
  }

  /// Logs in with the seeded demo account and asserts the dashboard greets
  /// that user.
  Future<void> loginAsDemoUser() async {
    await submitCredentials(
      email: TestData.demoEmail,
      password: TestData.demoPassword,
    );
    await _dashboard.waitUntilVisible();
    expect(
      _dashboard.greetingText,
      contains(TestData.demoFullName),
      reason: 'the dashboard must greet the logged-in user by name',
    );
  }

  /// Asserts the login screen rejected the attempt and stayed put.
  Future<void> expectLoginRejected() async {
    expect(
      _login.isVisible,
      isTrue,
      reason: 'a failed login must keep the user on the login screen',
    );
    expect(
      _dashboard.isVisible,
      isFalse,
      reason: 'a failed login must not reach the dashboard',
    );
  }

  /// Asserts the visible error message — the app never reveals whether the
  /// email exists, so both wrong-email and wrong-password show this one.
  void expectGenericCredentialsError() {
    expect(
      _login.hasErrorText('Correo o contraseña incorrectos'),
      isTrue,
      reason: 'invalid credentials must show the generic inline error',
    );
  }

  /// Walks the three onboarding slides and finishes on the last one.
  Future<void> completeOnboarding() async {
    await _onboarding.waitUntilVisible();
    await _onboarding.next();
    await _onboarding.next();
    await _onboarding.start();
  }

  /// Skips the onboarding from the first slide.
  Future<void> skipOnboarding() async {
    await _onboarding.waitUntilVisible();
    await _onboarding.skip();
  }

  /// Confirms the submit button stays disabled until the form is valid.
  Future<void> expectSubmitDisabledFor({
    required String email,
    required String password,
  }) async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    expect(
      _login.isSubmitEnabled,
      isFalse,
      reason: 'live validation must block submission for "$email"',
    );
  }
}
