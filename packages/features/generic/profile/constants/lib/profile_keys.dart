import 'package:flutter/foundation.dart';

/// Keys of the profile view (F16).
class ProfileKeys {
  const ProfileKeys._();

  static const Key view = Key('profile_view');
  static const Key editProfileButton = Key('edit_profile_button');
  static const Key nameInput = Key('profile_name_input');
  static const Key phoneInput = Key('profile_phone_input');
  static const Key avatarPickerButton = Key('avatar_picker_button');
  static const Key saveProfileButton = Key('save_profile_button');
  static const Key changePasswordButton = Key('change_password_button');
  static const Key currentPasswordInput = Key('current_password_input');
  static const Key newPasswordInput = Key('profile_new_password_input');
  static const Key confirmNewPasswordInput = Key(
    'profile_confirm_new_password_input',
  );
  static const Key submitPasswordButton = Key('profile_submit_password_button');
  static const Key deleteAccountButton = Key('delete_account_button');
  static const Key confirmDeleteAccountDialog = Key(
    'confirm_delete_account_dialog',
  );
  static const Key confirmDeleteAccountSecondDialog = Key(
    'confirm_delete_account_second_dialog',
  );
  static const Key goToAddressesButton = Key('go_to_addresses_button');
  static const Key goToSettingsButton = Key('go_to_settings_button');
  static const Key logoutButton = Key('profile_logout_button');
  static const Key logoutConfirmDialog = Key('profile_logout_confirm_dialog');
}

/// Keys of the addresses view (F16).
class AddressesKeys {
  const AddressesKeys._();

  static const Key view = Key('addresses_view');
  static const Key addButton = Key('add_address_button');
  static const Key formSheet = Key('address_form_sheet');
  static const Key labelInput = Key('address_label_input');
  static const Key line1Input = Key('address_line1_input');
  static const Key cityInput = Key('address_city_input');
  static const Key stateInput = Key('address_state_input');
  static const Key notesInput = Key('address_notes_input');
  static const Key saveButton = Key('address_save_button');
  static const Key confirmDeleteDialog = Key('address_confirm_delete_dialog');

  /// `addresses_state_<estado>`.
  static Key state(String state) => Key('addresses_state_$state');

  /// `address_item_<id>`.
  static Key item(String id) => Key('address_item_$id');

  /// `set_default_address_button_<id>`.
  static Key setDefaultButton(String id) =>
      Key('set_default_address_button_$id');

  /// `edit_address_button_<id>`.
  static Key editButton(String id) => Key('edit_address_button_$id');

  /// `delete_address_button_<id>`.
  static Key deleteButton(String id) => Key('delete_address_button_$id');
}
