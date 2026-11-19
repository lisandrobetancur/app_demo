/// Semantics identifiers of the authentication feature, grouped per view.
///
/// The counterpart of `authentication_keys.dart` for tools that cannot see a
/// Flutter `Key`: Appium and Maestro on mobile, Playwright on the web. Each one
/// reaches the platform's accessibility layer as Android's `resource-id`,
/// iOS's `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// Contracts, like the keys: `<screen>_<element>_<type>` in English
/// snake_case, stable across language, country, theme and platform. QA writes
/// locators against these strings, so renaming one breaks their suites
/// silently — the compiler cannot help on their side.
class LoginSemanticIds {
  const LoginSemanticIds._();

  static const String view = 'login_view';
  static const String titleText = 'login_title_text';
  static const String emailInput = 'login_email_input';
  static const String passwordInput = 'login_password_input';
  static const String togglePasswordVisibilityButton =
      'login_toggle_password_visibility_button';

  /// The form-level error (wrong credentials, server failure). A field's own
  /// validation error is part of that field's node instead.
  static const String errorText = 'login_error_text';
  static const String submitButton = 'login_submit_button';
  static const String goToRegisterButton = 'login_go_to_register_button';
  static const String goToRecoverPasswordButton =
      'login_go_to_recover_password_button';
}

/// Semantics identifiers of the register view.
class RegisterSemanticIds {
  const RegisterSemanticIds._();

  static const String view = 'register_view';
  static const String titleText = 'register_title_text';
  static const String fullNameInput = 'register_full_name_input';
  static const String emailInput = 'register_email_input';
  static const String phoneInput = 'register_phone_input';
  static const String passwordInput = 'register_password_input';
  static const String togglePasswordVisibilityButton =
      'register_toggle_password_visibility_button';
  static const String confirmPasswordInput = 'register_confirm_password_input';

  /// Carries the checked state: `checked` on Android, `aria-checked` on web.
  static const String termsCheckbox = 'register_terms_checkbox';
  static const String errorText = 'register_error_text';
  static const String submitButton = 'register_submit_button';
  static const String goToLoginButton = 'register_go_to_login_button';
}

/// Semantics identifiers of the password recovery view (all three steps).
class RecoverPasswordSemanticIds {
  const RecoverPasswordSemanticIds._();

  static const String view = 'recover_password_view';
  static const String titleText = 'recover_password_title_text';
  static const String stepIndicator = 'recover_step_indicator';
  static const String errorText = 'recover_error_text';

  // Step 1 · email.
  static const String emailInput = 'recover_email_input';
  static const String sendCodeButton = 'recover_send_code_button';

  // Step 2 · code.
  /// The demo banner whose text carries the issued code — the only place a
  /// test can read it from.
  static const String demoCodeText = 'recover_demo_code_text';
  static const String codeInput = 'recover_code_input';
  static const String validateCodeButton = 'recover_validate_code_button';

  // Step 3 · new password.
  static const String newPasswordInput = 'recover_new_password_input';
  static const String confirmNewPasswordInput =
      'recover_confirm_new_password_input';
  static const String submitButton = 'recover_submit_button';

  /// The snackbar shown once the password is changed, on the login screen.
  static const String successText = 'recover_success_text';
}
