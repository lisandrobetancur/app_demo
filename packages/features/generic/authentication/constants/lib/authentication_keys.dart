import 'package:flutter/foundation.dart';

/// Widget keys of the authentication feature, grouped per view.
///
/// Keys are contracts: stable across language, theme and platform.
class LoginKeys {
  const LoginKeys._();

  static const Key view = Key('login_view');
  static const Key emailInput = Key('email_input');
  static const Key passwordInput = Key('password_input');
  static const Key togglePasswordVisibilityButton = Key(
    'toggle_password_visibility_button',
  );
  static const Key rememberMeCheckbox = Key('remember_me_checkbox');
  static const Key submitButton = Key('login_submit_button');
  static const Key goToRegisterButton = Key('go_to_register_button');
  static const Key goToRecoverPasswordButton = Key(
    'go_to_recover_password_button',
  );
  static const Key logoutConfirmDialog = Key('logout_confirm_dialog');
}

/// Keys of the register view.
class RegisterKeys {
  const RegisterKeys._();

  static const Key view = Key('register_view');
  static const Key fullNameInput = Key('full_name_input');
  static const Key emailInput = Key('email_input');
  static const Key phoneInput = Key('phone_input');
  static const Key passwordInput = Key('password_input');
  static const Key confirmPasswordInput = Key('confirm_password_input');
  static const Key termsCheckbox = Key('terms_checkbox');
  static const Key submitButton = Key('register_submit_button');
  static const Key goToLoginButton = Key('go_to_login_button');
}

/// Keys of the password recovery view.
class RecoverPasswordKeys {
  const RecoverPasswordKeys._();

  static const Key view = Key('recover_password_view');
  static const Key emailInput = Key('recover_email_input');
  static const Key sendCodeButton = Key('recover_send_code_button');
  static const Key codeInput = Key('recover_code_input');
  static const Key validateCodeButton = Key('recover_validate_code_button');
  static const Key newPasswordInput = Key('new_password_input');
  static const Key confirmNewPasswordInput = Key('confirm_new_password_input');
  static const Key submitButton = Key('recover_submit_button');
  static const Key demoCodeBanner = Key('recover_demo_code_banner');
}
