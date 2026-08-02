part of com.demo.market.profile.core.state.profile;

/// Riverpod handle for [ProfileViewModel].
final NotifierProvider<ProfileViewModel, ProfileState>
profileViewModelProvider = NotifierProvider<ProfileViewModel, ProfileState>(
  ProfileViewModel.new,
);
