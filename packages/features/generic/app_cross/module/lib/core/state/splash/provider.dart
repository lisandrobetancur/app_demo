part of com.demo.market.app_cross.core.state.splash;

/// Riverpod handle for [SplashViewModel].
final NotifierProvider<SplashViewModel, SplashState> splashViewModelProvider =
    NotifierProvider<SplashViewModel, SplashState>(SplashViewModel.new);
