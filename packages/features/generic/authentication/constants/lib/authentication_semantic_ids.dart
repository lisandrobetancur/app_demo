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
