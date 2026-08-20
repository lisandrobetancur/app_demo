import 'package:patrol/patrol.dart';

import '../steps/steps.dart';
import '../support/support.dart';

void main() {
  e2eTest(
    'Inicio de sesión con usuario y contraseña correctos',
    tags: <String>[Tags.smoke, Tags.success],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.blocker,
        description:
            'El usuario debe poder iniciar sesión con credenciales válidas y ser recibido por su nombre en el dashboard.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      testParam('User', TestData.demoEmail);

      await steps.auth.loginAsDemoUser();
    },
  );

  e2eTest(
    'Intento inicio de sesión con credenciales inválidas',
    tags: <String>[Tags.smoke, Tags.negative],
    (PatrolIntegrationTester $) async {
      scenario(
        feature: Features.authentication,
        severity: Severity.critical,
        description:
            'El usuario no debe poder iniciar sesión con credenciales inválidas.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      for (final DataRecord row in TestData.invalidLogins) {
        final String label = row.string('case');
        testParam(label, '${row.string('email')} / ${row.string('password')}');
        Log.info('Invalid case: $label');

        await steps.auth.submitCredentials(
          email: row.string('email'),
          password: row.string('password'),
        );
        await steps.auth.expectLoginRejected();
        await steps.auth.expectGenericCredentialsError();
      }
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
            'Los campos del formulario de inicio de sesión deben validarse en tiempo real.',
      );
      testParam('Invalid email', 'not-an-email');

      await launchMarketApp($);
      final Steps steps = Steps($);

      await steps.auth.expectSubmitDisabledFor(
        email: 'not-an-email',
        password: TestData.demoPassword,
      );
    },
  );
}
