part of com.demo.market.profile.core.state.profile;

/// Immutable state of the profile screen (F16).
class ProfileState {
  const ProfileState({
    this.isEditing = false,
    this.fullName = '',
    this.phone = '',
    this.avatarBytes,
    this.pendingAvatarBytes,
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmNewPassword = '',
    this.isSaving = false,
    this.isChangingPassword = false,
    this.isDeleting = false,
    this.errorKey,
    this.lastEventKey,
  });

  final bool isEditing;
  final String fullName;
  final String phone;

  /// Persisted avatar.
  final Uint8List? avatarBytes;

  /// Newly picked avatar, saved on submit.
  final Uint8List? pendingAvatarBytes;

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;
  final bool isSaving;
  final bool isChangingPassword;
  final bool isDeleting;
  final String? errorKey;

  /// One-shot translation key consumed by the view as a snackbar.
  final String? lastEventKey;

  String? get newPasswordErrorKey =>
      newPassword.isEmpty || Validators.isValidPassword(newPassword)
      ? null
      : 'authentication.validation.password_invalid';

  String? get confirmNewPasswordErrorKey =>
      confirmNewPassword.isEmpty || confirmNewPassword == newPassword
      ? null
      : 'authentication.validation.confirm_mismatch';

  bool get canSaveProfile => !isSaving && fullName.trim().length >= 3;

  bool get canChangePassword =>
      !isChangingPassword &&
      currentPassword.isNotEmpty &&
      Validators.isValidPassword(newPassword) &&
      confirmNewPassword == newPassword;

  ProfileState copyWith({
    bool? isEditing,
    String? fullName,
    String? phone,
    Uint8List? avatarBytes,
    Uint8List? pendingAvatarBytes,
    String? currentPassword,
    String? newPassword,
    String? confirmNewPassword,
    bool? isSaving,
    bool? isChangingPassword,
    bool? isDeleting,
    String? errorKey,
    String? lastEventKey,
    bool clearError = false,
    bool clearEvent = false,
    bool clearPendingAvatar = false,
    bool clearPasswords = false,
  }) => ProfileState(
    isEditing: isEditing ?? this.isEditing,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    avatarBytes: avatarBytes ?? this.avatarBytes,
    pendingAvatarBytes: clearPendingAvatar
        ? null
        : pendingAvatarBytes ?? this.pendingAvatarBytes,
    currentPassword: clearPasswords
        ? ''
        : currentPassword ?? this.currentPassword,
    newPassword: clearPasswords ? '' : newPassword ?? this.newPassword,
    confirmNewPassword: clearPasswords
        ? ''
        : confirmNewPassword ?? this.confirmNewPassword,
    isSaving: isSaving ?? this.isSaving,
    isChangingPassword: isChangingPassword ?? this.isChangingPassword,
    isDeleting: isDeleting ?? this.isDeleting,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
    lastEventKey: clearEvent ? null : lastEventKey ?? this.lastEventKey,
  );

  @override
  bool operator ==(Object other) =>
      other is ProfileState &&
      other.isEditing == isEditing &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.avatarBytes?.length == avatarBytes?.length &&
      other.pendingAvatarBytes?.length == pendingAvatarBytes?.length &&
      other.currentPassword == currentPassword &&
      other.newPassword == newPassword &&
      other.confirmNewPassword == confirmNewPassword &&
      other.isSaving == isSaving &&
      other.isChangingPassword == isChangingPassword &&
      other.isDeleting == isDeleting &&
      other.errorKey == errorKey &&
      other.lastEventKey == lastEventKey;

  @override
  int get hashCode => Object.hash(
    isEditing,
    fullName,
    phone,
    avatarBytes?.length,
    pendingAvatarBytes?.length,
    currentPassword,
    newPassword,
    confirmNewPassword,
    isSaving,
    isChangingPassword,
    isDeleting,
    errorKey,
    lastEventKey,
  );

  @override
  String toString() =>
      'ProfileState: editing:$isEditing saving:$isSaving error:$errorKey';
}
