import 'package:flutter_test/flutter_test.dart';

import '../pages/pages.dart';
import '../support/support.dart';
import 'base_steps.dart';

/// Business steps around authentication and session.
///
/// The contract of this layer:
///
///  * a step reads like something a person does ("log in as the demo user"),
///    not like a sequence of taps;
///  * a step may compose several pages and may assert the outcome it
///    promises, so a test does not have to;
///  * a step never contains a locator — those live in the page objects;
///  * every step goes through [step], which names it, captures the screen it
///    left behind and reports its outcome to the Allure report.
class AuthSteps extends BaseSteps {
  AuthSteps(super.$)
    : _login = LoginPage($),
      _onboarding = OnboardingPage($),
      _dashboard = DashboardPage($);

  final LoginPage _login;
  final OnboardingPage _onboarding;
  final DashboardPage _dashboard;

  /// Fills the form and submits, without asserting the outcome — used by both
  /// the happy path and the failure cases.
  Future<void> submitCredentials({
    required String email,
    required String password,
  }) => step('Submit credentials for $email', () async {
    await _login.waitUntilVisible();
    await _login.enterEmail(email);
    await _login.enterPassword(password);
    await _login.submit();
  });

  /// Logs in with the seeded demo account and asserts the dashboard greets
  /// that user.
  Future<void> loginAsDemoUser() => step('Log in as the demo user', () async {
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
  });

  /// Asserts the login screen rejected the attempt and stayed put.
  Future<void> expectLoginRejected() => step(
    'Expect the login to be rejected',
    () async {
      // Soft: a rejected login has two halves — it stays put *and* it does
      // not slip through. With a hard `expect`, the first failure hides the
      // second, and "still on login" versus "also reached the dashboard"
      // point at very different bugs.
      softly
          .assertThat(_login.isVisible)
          .describedAs('a failed login must keep the user on the login screen')
          .isTrue();
      softly
          .assertThat(_dashboard.isVisible)
          .describedAs('a failed login must not reach the dashboard')
          .isFalse();
    },
  );

  /// Asserts the visible error message — the app never reveals whether the
  /// email exists, so both wrong-email and wrong-password show this one.
  Future<void> expectGenericCredentialsError() =>
      step('Expect the generic credentials error', () async {
        expect(
          _login.hasErrorText('Correo o contraseña incorrectos'),
          isTrue,
          reason: 'invalid credentials must show the generic inline error',
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
    expect(
      _login.isSubmitEnabled,
      isFalse,
      reason: 'live validation must block submission for "$email"',
    );
  });
}
