part of com.demo.market.profile.core.state.profile;

/// Controller of the profile screen.
class ProfileViewModel extends ViewModel<ProfileState> {
  ProfileViewModel({ProfileState? state})
    : super(state ?? const ProfileState());

  @override
  void postInit() {
    service = ref.read(profileServiceProvider);
    navigatorNotifier = ref.read(profileNavigator.notifier);
    runPostBuild(loadFromSession);
  }

  late IProfileService service;
  late ProfileNavigator navigatorNotifier;

  AuthUser? get _user => ref.read(authSessionProvider);

  Future<void> loadFromSession() async {
    final AuthUser? user = _user;
    if (user == null) {
      return;
    }
    final Object? key = mountedKey;
    final Uint8List? avatar = await service.avatarBytes(user.id);
    if (key != mountedKey) {
      return;
    }
    state = state.copyWith(
      fullName: user.fullName,
      phone: user.phone ?? '',
      avatarBytes: avatar,
    );
  }

  void startEditing() => state = state.copyWith(isEditing: true);

  void cancelEditing() {
    state = state.copyWith(isEditing: false, clearPendingAvatar: true);
    unawaited(loadFromSession());
  }

  void setFullName(String value) =>
      state = state.copyWith(fullName: value, clearError: true);

  void setPhone(String value) =>
      state = state.copyWith(phone: value, clearError: true);

  void setPendingAvatar(Uint8List bytes) =>
      state = state.copyWith(pendingAvatarBytes: bytes);

  Future<void> saveProfile() async {
    final AuthUser? user = _user;
    if (user == null || !state.canSaveProfile) {
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await service.updateProfile(
        userId: user.id,
        fullName: state.fullName,
        phone: state.phone,
        avatarBytes: state.pendingAvatarBytes,
      );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSaving: false,
        isEditing: false,
        clearPendingAvatar: true,
        lastEventKey: 'profile.home.saved_message',
      );
      await loadFromSession();
    } on Object catch (error, stackTrace) {
      log.error('profile.save', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isSaving: false,
        errorKey: 'profile.home.save_error',
      );
    }
  }

  void setCurrentPassword(String value) =>
      state = state.copyWith(currentPassword: value, clearError: true);

  void setNewPassword(String value) =>
      state = state.copyWith(newPassword: value, clearError: true);

  void setConfirmNewPassword(String value) =>
      state = state.copyWith(confirmNewPassword: value, clearError: true);

  Future<void> changePassword() async {
    final AuthUser? user = _user;
    if (user == null || !state.canChangePassword) {
      return;
    }
    state = state.copyWith(isChangingPassword: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await ref
          .read(authenticationServiceProvider)
          .changePassword(
            userId: user.id,
            currentPassword: state.currentPassword,
            newPassword: state.newPassword,
          );
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isChangingPassword: false,
        clearPasswords: true,
        lastEventKey: 'profile.home.password_changed_message',
      );
    } on AuthException catch (error) {
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isChangingPassword: false,
        errorKey: error.code.messageKey,
      );
    } on Object catch (error, stackTrace) {
      log.error('profile.changePassword', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isChangingPassword: false,
        errorKey: 'profile.home.save_error',
      );
    }
  }

  /// Deletes the account (double confirmation happens in the view).
  Future<void> deleteAccount() async {
    final AuthUser? user = _user;
    if (user == null || state.isDeleting) {
      return;
    }
    state = state.copyWith(isDeleting: true, clearError: true);
    final Object? key = mountedKey;
    try {
      await service.deleteAccount(user.id);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(isDeleting: false);
      navigatorNotifier.goToLogin();
    } on Object catch (error, stackTrace) {
      log.error('profile.deleteAccount', error, stackTrace);
      if (key != mountedKey) {
        return;
      }
      state = state.copyWith(
        isDeleting: false,
        errorKey: 'profile.home.save_error',
      );
    }
  }

  void consumeEvent() => state = state.copyWith(clearEvent: true);

  /// Logout from the profile tab.
  Future<void> logout() async {
    await ref.read(authenticationServiceProvider).logout();
    navigatorNotifier.goToLogin();
  }
}
