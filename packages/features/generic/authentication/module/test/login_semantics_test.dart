import 'package:authentication/core/state/login/login.dart';
import 'package:authentication/ui/views/login/login.dart';
import 'package:authentication_constants/authentication_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The login view's semantics identifiers are a contract with QA: Playwright,
/// Appium and Maestro address the screen by them and see nothing else.
///
/// Finding the identifier is not enough. A `Semantics` merges into the nearest
/// node above it, so an identifier placed one level off lands on an empty
/// container — found by the finder, useless to a tool that has to type into
/// it or tap it. Each one is therefore checked on the node it has to be on.
void main() {
  late SemanticsHandle semantics;

  setUp(() => semantics = SemanticsBinding.instance.ensureSemantics());
  tearDown(() => semantics.dispose());

  Future<void> pumpLogin(WidgetTester tester, {LoginState? state}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          loginViewModelProvider.overrideWith(
            () => _InertLoginViewModel(state ?? const LoginState()),
          ),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );
    await tester.pump();
  }

  Finder byId(String id) => find.bySemanticsIdentifier(id);

  testWidgets('every identifier lands on one node of the right kind', (
    WidgetTester tester,
  ) async {
    await pumpLogin(tester);

    expect(byId(LoginSemanticIds.view), findsOneWidget);
    expect(
      tester.getSemantics(byId(LoginSemanticIds.titleText)).label,
      isNotEmpty,
    );

    for (final String input in <String>[
      LoginSemanticIds.emailInput,
      LoginSemanticIds.passwordInput,
    ]) {
      expect(byId(input), findsOneWidget, reason: input);
      expect(
        tester.getSemantics(byId(input)),
        isSemantics(isTextField: true, hasTapAction: true),
        reason: '$input has to be the editable node, not a parent',
      );
    }
    expect(
      tester.getSemantics(byId(LoginSemanticIds.passwordInput)),
      isSemantics(isObscured: true),
    );

    // The toggle predates the identifiers: its `Semantics(label, button)`
    // forms a node of its own above the IconButton's. The identifier went onto
    // that existing Semantics rather than a new one nested inside, so it sits
    // on the labelled node while the tap lives on its only child — same rect,
    // so a tool tapping the element's centre still reaches it.
    final SemanticsNode toggle = tester.getSemantics(
      byId(LoginSemanticIds.togglePasswordVisibilityButton),
    );
    expect(toggle, isSemantics(isButton: true));
    expect(toggle.label, isNotEmpty);
    final List<SemanticsNode> toggleChildren = <SemanticsNode>[];
    toggle.visitChildren((SemanticsNode child) {
      toggleChildren.add(child);
      return true;
    });
    expect(toggleChildren, hasLength(1));
    // A child's rect is in its parent's coordinates: covering the whole
    // parent reads as the origin plus the parent's size.
    expect(toggleChildren.single.rect, Offset.zero & toggle.rect.size);
    expect(
      toggleChildren.single,
      isSemantics(isButton: true, hasTapAction: true),
    );

    for (final String button in <String>[
      LoginSemanticIds.goToRegisterButton,
      LoginSemanticIds.goToRecoverPasswordButton,
    ]) {
      expect(byId(button), findsOneWidget, reason: button);
      expect(
        tester.getSemantics(byId(button)),
        isSemantics(isButton: true, hasTapAction: true),
        reason: '$button has to be the tappable node, not a parent',
      );
    }

    // Empty form: the submit is there but disabled, and says so — the state a
    // black-box test reads as `enabled=false` / `aria-disabled="true"`.
    expect(byId(LoginSemanticIds.submitButton), findsOneWidget);
    expect(
      tester.getSemantics(byId(LoginSemanticIds.submitButton)),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );

    expect(byId(LoginSemanticIds.errorText), findsNothing);
  });

  testWidgets('the submit turns enabled once the form is valid', (
    WidgetTester tester,
  ) async {
    await pumpLogin(
      tester,
      state: const LoginState(email: 'qa@demo.com', password: 'secret'),
    );

    expect(
      tester.getSemantics(byId(LoginSemanticIds.submitButton)),
      isSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('the form-level error carries its identifier and its text', (
    WidgetTester tester,
  ) async {
    await pumpLogin(
      tester,
      state: const LoginState(errorKey: 'authentication.errors.generic'),
    );

    expect(byId(LoginSemanticIds.errorText), findsOneWidget);
    expect(
      tester.getSemantics(byId(LoginSemanticIds.errorText)).label,
      isNotEmpty,
    );
  });
}

/// The real view model, minus its dependencies: `postInit` would resolve the
/// authentication service and the navigator, and neither is needed to render.
class _InertLoginViewModel extends LoginViewModel {
  _InertLoginViewModel(LoginState state) : super(state: state);

  @override
  void postInit() {}
}
