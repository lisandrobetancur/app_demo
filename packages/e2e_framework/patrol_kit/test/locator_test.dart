import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// The semantics strategies, which are the two that depend on a tree the other
/// finders do not need — so they are the two worth proving rather than
/// assuming.
///
/// Every case here is a `testWidgets` even where nothing is pumped, and that is
/// not an oversight: `find.bySemanticsIdentifier` throws when it is *built*,
/// not when it matches, so a `Loc.semantics` cannot be constructed at all
/// without an active [SemanticsHandle]. The same reason the handle is disposed
/// by hand rather than through `addTearDown` — the framework checks for leaked
/// handles before tear-downs run.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  group('an identifier locates the element', () {
    testWidgets('and is what the app declares, not what it renders', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          Semantics(
            identifier: 'login_submit',
            container: true,
            child: const Text('Entrar'),
          ),
        ),
      );

      expect(Loc.semantics('login_submit').finder, findsOneWidget);

      handle.dispose();
    });

    testWidgets('and is not the label, which is the whole point', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      // The label is the translated text; the identifier is not. A suite that
      // switched language would keep the second and lose the first, which is
      // the reason Loc.semantics is preferred over Loc.semanticsLabel.
      await tester.pumpWidget(
        wrap(
          Semantics(
            identifier: 'login_submit',
            label: 'Iniciar sesión',
            container: true,
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(Loc.semantics('login_submit').finder, findsOneWidget);
      expect(Loc.semanticsLabel('Iniciar sesión').finder, findsOneWidget);
      expect(Loc.semantics('Iniciar sesión').finder, findsNothing);

      handle.dispose();
    });
  });

  group('a locator says how it was found', () {
    testWidgets('so a failure names the strategy and not a finder dump', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      expect(
        Loc.semantics('login_submit').description,
        "semantics identifier 'login_submit'",
      );
      expect(
        Loc.semanticsLabel('Entrar').description,
        "semantics label 'Entrar'",
      );

      handle.dispose();
    });

    testWidgets('and composition keeps reading as a sentence', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      final Loc scoped = Loc.type(Text).within(Loc.semantics('login_view'));

      expect(
        scoped.description,
        "Text widget within semantics identifier 'login_view'",
      );

      handle.dispose();
    });
  });
}
