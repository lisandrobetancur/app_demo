/// Translations of the authentication feature.
///
/// Key convention: `feature.screen.element` (snake_case, ≥3 levels). The
/// shell merges every feature map into the easy_localization loader.
class AuthenticationLanguages {
  const AuthenticationLanguages._();

  static const Map<String, dynamic> es = <String, dynamic>{
    'authentication': <String, dynamic>{
      'login': <String, dynamic>{
        'title': 'Inicia sesión',
        'subtitle': 'Compra y vende vehículos ligeros en tu ciudad',
        'email_label': 'Correo electrónico',
        'password_label': 'Contraseña',
        'remember_me': 'Recordarme',
        'submit_button': 'Iniciar sesión',
        'go_to_register': 'Crear una cuenta',
        'go_to_recover': '¿Olvidaste tu contraseña?',
        'show_password': 'Mostrar contraseña',
        'hide_password': 'Ocultar contraseña',
        'demo_hint': 'Demo: ana@market.demo / Demo1234',
      },
      'register': <String, dynamic>{
        'title': 'Crea tu cuenta',
        'full_name_label': 'Nombre completo',
        'email_label': 'Correo electrónico',
        'phone_label': 'Teléfono (opcional)',
        'password_label': 'Contraseña',
        'confirm_password_label': 'Confirmar contraseña',
        'terms_label': 'Acepto los términos y condiciones',
        'submit_button': 'Registrarme',
        'go_to_login': 'Ya tengo una cuenta',
      },
      'recover': <String, dynamic>{
        'title': 'Recuperar contraseña',
        'step_email': 'Correo',
        'step_code': 'Código',
        'step_password': 'Nueva clave',
        'email_label': 'Correo registrado',
        'send_code_button': 'Enviar código',
        'code_label': 'Código de 6 dígitos',
        'validate_code_button': 'Validar código',
        'new_password_label': 'Nueva contraseña',
        'confirm_new_password_label': 'Confirmar nueva contraseña',
        'submit_button': 'Cambiar contraseña',
        'demo_code_banner':
            'Código de demostración: {code}. En producción llegaría por correo.',
        'success_message': 'Contraseña actualizada. Inicia sesión de nuevo.',
        'back_to_login': 'Volver al inicio de sesión',
      },
      'validation': <String, dynamic>{
        'email_invalid': 'Ingresa un correo válido',
        'password_invalid':
            'Mínimo 8 caracteres, con al menos una letra y un número',
        'confirm_mismatch': 'Las contraseñas no coinciden',
        'name_required': 'El nombre debe tener al menos 3 caracteres',
        'terms_required': 'Debes aceptar los términos',
      },
      'errors': <String, dynamic>{
        'invalid_credentials': 'Correo o contraseña incorrectos',
        'email_in_use': 'Ya existe una cuenta con este correo',
        'email_not_found': 'No hay una cuenta con este correo',
        'invalid_code': 'El código no es válido',
        'wrong_password': 'La contraseña actual no es correcta',
        'generic': 'Algo salió mal. Inténtalo de nuevo.',
      },
    },
  };

  static const Map<String, dynamic> en = <String, dynamic>{
    'authentication': <String, dynamic>{
      'login': <String, dynamic>{
        'title': 'Sign in',
        'subtitle': 'Buy and sell light vehicles in your city',
        'email_label': 'Email',
        'password_label': 'Password',
        'remember_me': 'Remember me',
        'submit_button': 'Sign in',
        'go_to_register': 'Create an account',
        'go_to_recover': 'Forgot your password?',
        'show_password': 'Show password',
        'hide_password': 'Hide password',
        'demo_hint': 'Demo: ana@market.demo / Demo1234',
      },
      'register': <String, dynamic>{
        'title': 'Create your account',
        'full_name_label': 'Full name',
        'email_label': 'Email',
        'phone_label': 'Phone (optional)',
        'password_label': 'Password',
        'confirm_password_label': 'Confirm password',
        'terms_label': 'I accept the terms and conditions',
        'submit_button': 'Sign up',
        'go_to_login': 'I already have an account',
      },
      'recover': <String, dynamic>{
        'title': 'Recover password',
        'step_email': 'Email',
        'step_code': 'Code',
        'step_password': 'New password',
        'email_label': 'Registered email',
        'send_code_button': 'Send code',
        'code_label': '6-digit code',
        'validate_code_button': 'Validate code',
        'new_password_label': 'New password',
        'confirm_new_password_label': 'Confirm new password',
        'submit_button': 'Change password',
        'demo_code_banner':
            'Demo code: {code}. In production it would arrive by email.',
        'success_message': 'Password updated. Sign in again.',
        'back_to_login': 'Back to sign in',
      },
      'validation': <String, dynamic>{
        'email_invalid': 'Enter a valid email',
        'password_invalid': 'At least 8 characters, with a letter and a number',
        'confirm_mismatch': 'Passwords do not match',
        'name_required': 'Name must be at least 3 characters long',
        'terms_required': 'You must accept the terms',
      },
      'errors': <String, dynamic>{
        'invalid_credentials': 'Wrong email or password',
        'email_in_use': 'An account with this email already exists',
        'email_not_found': 'There is no account with this email',
        'invalid_code': 'The code is not valid',
        'wrong_password': 'The current password is not correct',
        'generic': 'Something went wrong. Try again.',
      },
    },
  };
}
