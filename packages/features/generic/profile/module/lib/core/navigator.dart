part of com.demo.market.profile.core;

/// Riverpod handle for [ProfileNavigator].
final NotifierProvider<ProfileNavigator, void> profileNavigator =
    NotifierProvider<ProfileNavigator, void>(ProfileNavigator.new);

/// Navigation intents of the profile feature.
class ProfileNavigator extends FeatureNavigator {
  void goToProfile() => navigation.goNamed(ProfileRoutes.profileName);

  void goToAddresses() => navigation.pushNamed(ProfileRoutes.addressesName);

  /// Cross-feature destinations, by path only.
  void goToSettings() => navigation.go('/settings');

  void goToLogin() => navigation.go('/authentication/login');

  void back() => navigation.pop();
}
