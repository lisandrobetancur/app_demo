/// Semantics identifiers of the profile feature, grouped per view.
///
/// The counterpart of `profile_keys.dart` for tools that cannot see a Flutter
/// `Key`: Appium and Maestro on mobile, Playwright on the web. Each one reaches
/// the platform's accessibility layer as Android's `resource-id`, iOS's
/// `accessibilityIdentifier` and web's `flt-semantics-identifier`.
///
/// Contracts, like the keys: `<screen>_<element>_<type>` in English
/// snake_case, stable across language, country, theme and platform. Items of a
/// list carry their id, never their position.

/// Semantics identifiers of the profile view.
class ProfileSemanticIds {
  const ProfileSemanticIds._();

  static const String view = 'profile_view';
  static const String titleText = 'profile_title_text';
  static const String avatarImage = 'profile_avatar_image';
  static const String nameText = 'profile_name_text';
  static const String emailText = 'profile_email_text';
  static const String phoneText = 'profile_phone_text';
  static const String editButton = 'profile_edit_button';

  // Edit form.
  static const String nameInput = 'profile_name_input';
  static const String phoneInput = 'profile_phone_input';
  static const String avatarPickerButton = 'profile_avatar_picker_button';
  static const String cancelEditButton = 'profile_cancel_edit_button';
  static const String saveButton = 'profile_save_button';

  // Change-password sheet.
  static const String changePasswordButton = 'profile_change_password_button';
  static const String passwordSheet = 'profile_password_sheet';
  static const String currentPasswordInput = 'profile_current_password_input';
  static const String newPasswordInput = 'profile_new_password_input';
  static const String confirmNewPasswordInput =
      'profile_confirm_new_password_input';
  static const String passwordErrorText = 'profile_password_error_text';
  static const String submitPasswordButton = 'profile_submit_password_button';

  // Navigation and session.
  static const String goToAddressesButton = 'profile_go_to_addresses_button';
  static const String goToSettingsButton = 'profile_go_to_settings_button';
  static const String logoutButton = 'profile_logout_button';
  static const String logoutDialog = 'profile_logout_dialog';
  static const String logoutConfirmButton =
      'profile_logout_dialog_confirm_button';
  static const String logoutCancelButton =
      'profile_logout_dialog_cancel_button';

  // Danger zone.
  static const String errorText = 'profile_error_text';
  static const String deleteAccountButton = 'profile_delete_account_button';
  static const String deleteAccountDialog = 'profile_delete_account_dialog';
  static const String deleteAccountConfirmButton =
      'profile_delete_account_dialog_confirm_button';
  static const String deleteAccountCancelButton =
      'profile_delete_account_dialog_cancel_button';
  static const String deleteAccountSecondDialog =
      'profile_delete_account_second_dialog';
  static const String deleteAccountSecondConfirmButton =
      'profile_delete_account_second_dialog_confirm_button';
  static const String deleteAccountSecondCancelButton =
      'profile_delete_account_second_dialog_cancel_button';

  /// The snackbar confirming an action (profile saved, password changed, …).
  static const String messageText = 'profile_message_text';
}
