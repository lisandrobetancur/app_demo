import 'package:authentication_constants/authentication_constants.dart';
import 'package:design_system/design_system.dart';
import 'package:patrol/patrol.dart';

import 'base_page.dart';

/// F04 · Login.
class LoginPage extends BasePage {
  const LoginPage(super.$);

  @override
  PatrolFinder get root => $(LoginKeys.view);

  PatrolFinder get emailInput => $(LoginKeys.emailInput);

  PatrolFinder get passwordInput => $(LoginKeys.passwordInput);

  PatrolFinder get submitButton => $(LoginKeys.submitButton);

  PatrolFinder get rememberMeCheckbox => $(LoginKeys.rememberMeCheckbox);

  PatrolFinder get togglePasswordButton =>
      $(LoginKeys.togglePasswordVisibilityButton);

  PatrolFinder get goToRegisterButton => $(LoginKeys.goToRegisterButton);

  PatrolFinder get goToRecoverPasswordButton =>
      $(LoginKeys.goToRecoverPasswordButton);

  Future<void> enterEmail(String email) =>
      act('login_email_filled', () => emailInput.enterText(email));

  Future<void> enterPassword(String password) =>
      act('login_password_filled', () => passwordInput.enterText(password));

  Future<void> toggleRememberMe() =>
      act('login_remember_me_toggled', () => rememberMeCheckbox.tap());

  Future<void> togglePasswordVisibility() => act(
    'login_password_visibility_toggled',
    () => togglePasswordButton.tap(),
  );

  Future<void> submit() => act('login_submitted', () => submitButton.tap());

  Future<void> openRegister() =>
      act('register_opened', () => goToRegisterButton.tap());

  Future<void> openPasswordRecovery() =>
      act('password_recovery_opened', () => goToRecoverPasswordButton.tap());

  /// False while live validation still blocks submission.
  bool get isSubmitEnabled =>
      $.tester.widget<AppButton>(submitButton.finder).onPressed != null;

  /// The inline error under the form, or `null` when there is none.
  ///
  /// The controller stores a translation key and the view renders it through
  /// `easy_localization`, so the assertion is done on the visible text.
  bool hasErrorText(String text) => $(text).exists;
}
