import 'package:patrol/patrol.dart';

import 'steps/steps.dart';
import 'support/support.dart';

/// F04 · Login and session.
///
/// The test body only speaks business language; every locator lives in a page
/// object and every interaction in a step.
void main() {
  patrolTest('logs in with the seeded demo account', (
    PatrolIntegrationTester $,
  ) async {
    scenario(
      epic: 'Acceso',
      feature: 'Autenticación',
      story: 'Iniciar sesión con credenciales válidas',
      severity: Severity.blocker,
      description:
          'Sin login no hay carrito, pedidos ni perfil: es la puerta de '
          'entrada a todo lo demás.',
    );
    testParam('Usuario', TestData.demoEmail);

    await launchMarketApp($);
    final Steps steps = Steps($);

    await steps.auth.loginAsDemoUser();
  });

  patrolTest('rejects wrong credentials without revealing the email', (
    PatrolIntegrationTester $,
  ) async {
    scenario(
      epic: 'Acceso',
      feature: 'Autenticación',
      story: 'Rechazar credenciales inválidas sin filtrar si el correo existe',
      severity: Severity.critical,
      description:
          'El mensaje debe ser el genérico: distinguir "correo no existe" de '
          '"contraseña incorrecta" permite enumerar cuentas registradas.',
    );
    testParam('Usuario', TestData.demoEmail);
    testParam('Contraseña', 'WrongPassword1');

    await launchMarketApp($);
    final Steps steps = Steps($);

    await steps.auth.submitCredentials(
      email: TestData.demoEmail,
      password: 'WrongPassword1',
    );

    await steps.auth.expectLoginRejected();
    await steps.auth.expectGenericCredentialsError();
  });

  patrolTest('keeps submission blocked while the form is invalid', (
    PatrolIntegrationTester $,
  ) async {
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
  });
}
