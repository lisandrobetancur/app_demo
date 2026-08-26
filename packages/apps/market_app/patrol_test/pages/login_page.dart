import 'package:authentication_constants/authentication_constants.dart';
import 'package:patrol/patrol.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// F04 · Login.
///
/// Written against the declarative locator layer: the block below is the only
/// place that knows *how* anything on this screen is found, and each line can
/// change strategy on its own.
class LoginPage extends BasePage {
  const LoginPage(super.$);

  // --- Locators ------------------------------------------------------------
  //
  // One strategy per element, chosen by hand. These use the keys the feature
  // already declares, so a rename breaks at compile time. On a screen with no
  // keys the same block would read:
  //
  //   static final Loc _submitButton = Loc.text('Iniciar sesión');
  //   static final Loc _emailInput   = Loc.type(AppTextField).at(0);
  //
  // and switching to a key later is one line, here.

  static final Loc _view = Loc.widgetKey(LoginKeys.view);
  static final Loc _emailInput = Loc.widgetKey(LoginKeys.emailInput);
  static final Loc _passwordInput = Loc.widgetKey(LoginKeys.passwordInput);
  static final Loc _submitButton = Loc.widgetKey(LoginKeys.submitButton);
  static final Loc _togglePasswordButton = Loc.widgetKey(
    LoginKeys.togglePasswordVisibilityButton,
  );
  static final Loc _goToRegisterButton = Loc.widgetKey(
    LoginKeys.goToRegisterButton,
  );
  static final Loc _goToRecoverPasswordButton = Loc.widgetKey(
    LoginKeys.goToRecoverPasswordButton,
  );

  // --- Elements ------------------------------------------------------------

  @override
  PatrolFinder get root => _view.resolve($);

  UiElement get emailInput => element(_emailInput);

  UiElement get passwordInput => element(_passwordInput);

  UiElement get submitButton => element(_submitButton);

  UiElement get togglePasswordButton => element(_togglePasswordButton);

  UiElement get goToRegisterButton => element(_goToRegisterButton);

  UiElement get goToRecoverPasswordButton =>
      element(_goToRecoverPasswordButton);

  // --- Actions -------------------------------------------------------------

  Future<void> enterEmail(String email) => emailInput.type(email);

  Future<void> enterPassword(String password) => passwordInput.type(password);

  Future<void> togglePasswordVisibility() => togglePasswordButton.click();

  Future<void> submit() => submitButton.click();

  /// The screen's own flow: fill the form and send it.
  ///
  /// Lives here and not in the steps layer because everything it touches is
  /// this screen's — which fields, in what order, which button. What the
  /// submission *led to* is not this page's business: the caller asserts
  /// that, on whatever screen the app answers with.
  Future<void> login({required String email, required String password}) async {
    await waitUntilVisible();
    await enterEmail(email);
    await enterPassword(password);
    await submit();
  }

  Future<void> openRegister() => goToRegisterButton.click();

  Future<void> openPasswordRecovery() => goToRecoverPasswordButton.click();

  // --- Reads ---------------------------------------------------------------

  /// False while live validation still blocks submission.
  ///
  /// Reads the button's own rule instead of reaching for `onPressed`: the
  /// design system also disables it while loading, which a raw callback check
  /// misses.
  bool get isSubmitEnabled => submitButton.isEnabled;

  /// The inline error under the form, or `null` when there is none.
  ///
  /// The controller stores a translation key and the view renders it through
  /// `easy_localization`, so the assertion is done on the visible text.
  bool hasErrorText(String text) => element(Loc.text(text)).isDisplayed;
}
