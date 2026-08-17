import 'package:patrol/patrol.dart';

import 'steps/steps.dart';
import 'support/support.dart';

/// F04 · Login and session.
///
/// The test body only speaks business language; every locator lives in a page
/// object and every interaction in a step.
void main() {
  e2eTest(
    'logs in with the seeded demo account',
    tags: <String>[Tags.smoke, Tags.exito],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Acceso',
        feature: 'Autenticación',
        story: 'Iniciar sesión con credenciales válidas',
        severity: Severity.blocker,
        description:
            'Sin login no hay carrito, pedidos ni perfil: es la puerta de '
            'entrada a todo lo demás.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      // Los `testParam` van DESPUÉS del arranque, no antes: leen de
      // `TestData`, y los datos viven en el bundle de assets, que no existe
      // hasta que la app arrancó. Además así registran lo que la prueba usó
      // de verdad, no lo que pensaba usar.
      testParam('Usuario', TestData.demoEmail);

      await steps.auth.loginAsDemoUser();
    },
  );

  e2eTest(
    'rejects wrong credentials without revealing the email',
    tags: <String>[Tags.smoke, Tags.negativo],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Acceso',
        feature: 'Autenticación',
        story:
            'Rechazar credenciales inválidas sin filtrar si el correo existe',
        severity: Severity.critical,
        description:
            'El mensaje debe ser el genérico: distinguir "correo no existe" de '
            '"contraseña incorrecta" permite enumerar cuentas registradas. Los '
            'casos vienen de patrol_test/data/invalid_logins.json.',
      );

      await launchMarketApp($);
      final Steps steps = Steps($);

      // Una prueba, varios casos. Recorrer las filas dentro del test y no
      // generar un test por fila es deliberado: los datos se leen del bundle
      // de assets, que sólo existe cuando la app ya arrancó — y `main()` se
      // ejecuta antes de eso. Además comparten un único arranque, que es lo
      // caro de un E2E.
      for (final DataRecord caso in TestData.invalidLogins) {
        final String etiqueta = caso.string('case');
        testParam(
          etiqueta,
          '${caso.string('email')} / ${caso.string('password')}',
        );
        Log.info('Caso inválido: $etiqueta');

        await steps.auth.submitCredentials(
          email: caso.string('email'),
          password: caso.string('password'),
        );
        await steps.auth.expectLoginRejected();
        await steps.auth.expectGenericCredentialsError();
      }
    },
  );

  e2eTest(
    'keeps submission blocked while the form is invalid',
    tags: <String>[Tags.regression, Tags.negativo],
    (PatrolIntegrationTester $) async {
      scenario(
        epic: 'Acceso',
        feature: 'Autenticación',
        story: 'Bloquear el envío mientras el formulario sea inválido',
        severity: Severity.normal,
        description:
            'La validación en vivo debe impedir el envío antes de gastar una '
            'llamada al backend.',
      );
      testParam('Correo inválido', 'not-an-email');

      await launchMarketApp($);
      final Steps steps = Steps($);

      await steps.auth.expectSubmitDisabledFor(
        email: 'not-an-email',
        password: TestData.demoPassword,
      );
    },
  );
}
