import 'package:patrol/patrol.dart';

import '../steps/steps.dart';
import '../support/support.dart';

/// F04 · Login: one test per case.
///
/// The three rejections used to share one test, looped over the data file.
/// Now each is its own test with its own name, its own row in the report and
/// its own screenshot on failure — and a red one names its case instead of
/// naming the loop.
///
/// The layering, uniform across all five: the TEST owns the data — it reads
/// its record inside the body and passes values down — the STEPS perform and
/// assert what they are handed, and the PAGE knows the screen. The read
/// happens inside the body and not in the header because the data lives in
/// the asset bundle, which does not exist until the app has launched; the
/// guard in `test/patrol_guards/test_order_test.dart` watches exactly that.
void main() {
  e2eTest(
    'Inicio de sesión con usuario y contraseña correctos',
    tags: <String>[Tags.smoke, Tags.success],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.blocker,
        description:
            'El usuario debe poder iniciar sesión con credenciales válidas y '
            'ser recibido por su nombre en el dashboard.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      testParam('Usuario', TestData.demoEmail);

      await steps.auth.login(
        email: TestData.demoEmail,
        password: TestData.demoPassword,
      );
      await steps.auth.expectLoggedInAs(TestData.demoFullName);
    },
  );

  e2eTest(
    'Intento de inicio de sesión con contraseña incorrecta',
    tags: <String>[Tags.smoke, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.critical,
        description:
            'Una contraseña que no es la del usuario debe ser rechazada con '
            'el error genérico, sin revelar cuál de los dos campos falló.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      final DataRecord data = TestData.invalidLogin('wrongPassword');
      testParam('Usuario', data.string('email'));

      await steps.auth.login(
        email: data.string('email'),
        password: data.string('password'),
      );
      await steps.auth.expectLoginRejected();
      await steps.auth.expectGenericCredentialsError();
    },
  );

  e2eTest(
    'Intento de inicio de sesión con un correo inexistente',
    tags: <String>[Tags.smoke, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.critical,
        description:
            'Un correo que no está registrado debe ser rechazado con el mismo '
            'error genérico que una contraseña incorrecta: la app no revela '
            'si una cuenta existe.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      final DataRecord data = TestData.invalidLogin('unknownEmail');
      testParam('Usuario', data.string('email'));

      await steps.auth.login(
        email: data.string('email'),
        password: data.string('password'),
      );
      await steps.auth.expectLoginRejected();
      await steps.auth.expectGenericCredentialsError();
    },
  );

  e2eTest(
    'Intento de inicio de sesión con la contraseña de otro usuario',
    tags: <String>[Tags.smoke, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.critical,
        description:
            'Una contraseña válida en el sistema pero de otra cuenta debe ser '
            'rechazada igual que cualquier credencial inválida.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      final DataRecord data = TestData.invalidLogin('foreignPassword');
      testParam('Usuario', data.string('email'));

      await steps.auth.login(
        email: data.string('email'),
        password: data.string('password'),
      );
      await steps.auth.expectLoginRejected();
      await steps.auth.expectGenericCredentialsError();
    },
  );

  e2eTest(
    'Validación de los campos de inicio de sesión',
    tags: <String>[Tags.regression, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.normal,
        description:
            'Los campos del formulario deben validarse en tiempo real: un '
            'correo mal formado bloquea el envío y unas credenciales bien '
            'formadas lo desbloquean.',
      );
      testParam('Correo inválido', 'not-an-email');

      await launchMarketApp($);
      final Steps steps = Steps($);

      await steps.auth.expectSubmitDisabledFor(
        email: 'not-an-email',
        password: TestData.demoPassword,
      );
      // The other half, and what keeps this test honest: a disabled button is
      // also what a dead app shows, so without this contrast the test passes
      // when no input reaches the form at all.
      await steps.auth.expectSubmitEnabledFor(
        email: TestData.demoEmail,
        password: TestData.demoPassword,
      );
    },
  );
}
