/// Translations owned by the shell (navigation chrome).
class ShellLanguages {
  const ShellLanguages._();

  static const Map<String, dynamic> es = <String, dynamic>{
    'shell': <String, dynamic>{
      'tabs': <String, dynamic>{
        'dashboard': 'Inicio',
        'catalog': 'Catálogo',
        'cart': 'Carrito',
        'orders': 'Órdenes',
        'profile': 'Perfil',
      },
      'not_found': <String, dynamic>{
        'title': 'Página no encontrada',
        'message': 'La ruta no existe o el recurso fue eliminado.',
        'go_home_button': 'Ir al inicio',
      },
    },
  };

  static const Map<String, dynamic> en = <String, dynamic>{
    'shell': <String, dynamic>{
      'tabs': <String, dynamic>{
        'dashboard': 'Home',
        'catalog': 'Catalog',
        'cart': 'Cart',
        'orders': 'Orders',
        'profile': 'Profile',
      },
      'not_found': <String, dynamic>{
        'title': 'Page not found',
        'message': 'The route does not exist or the resource was removed.',
        'go_home_button': 'Go home',
      },
    },
  };
}
