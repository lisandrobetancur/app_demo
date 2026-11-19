// Generates the semantics-identifier inventory for QA from the source of truth:
// every `*_semantic_ids.dart` in the feature constants packages (plus the
// shell's), and where each constant is used.
//
//   dart run packages/e2e_framework/tool/semantic_ids/inventory.dart
//       [--ts <path>]
//
// Always rewrites docs/semantic-ids.md. With --ts it also writes the
// TypeScript mirror the Playwright suite imports (its
// tests/support/semantic-ids.ts), so both sides come from the same parse and a
// rename reaches them together.
//
// Only dart:io: it runs with no package resolution, from the repo root.
import 'dart:io';

void main(List<String> args) {
  final int tsFlag = args.indexOf('--ts');
  final String? tsPath = tsFlag >= 0 && tsFlag + 1 < args.length
      ? args[tsFlag + 1]
      : null;

  final List<IdClass> classes = <IdClass>[
    for (final File file in _idFiles()) ..._parse(file),
  ]..sort((IdClass a, IdClass b) => _order(a.name).compareTo(_order(b.name)));
  final List<File> sources = _widgetFiles().toList();
  for (final IdClass idClass in classes) {
    for (final IdMember member in idClass.members) {
      // A family may be reached through a getter of its own class
      // (`ratingStars` builds the five `ratingStar(n)`): count those uses too.
      final String via = member.viaGetter == null ? '' : '|${member.viaGetter}';
      final RegExp use = RegExp(
        '\\b${idClass.name}\\.(?:${member.name}${member.isFamily ? r'\s*\(' : r'\b'}$via)',
      );
      member.usedIn.addAll(
        <String>[
          for (final File file in sources)
            if (use.hasMatch(file.readAsStringSync())) _relative(file.path),
        ]..sort(),
      );
    }
  }

  File('docs/semantic-ids.md').writeAsStringSync(_markdown(classes));
  stdout.writeln(
    'docs/semantic-ids.md: ${classes.length} screens, '
    '${classes.fold<int>(0, (int n, IdClass c) => n + c.members.length)} identifiers',
  );
  final List<String> unused = <String>[
    for (final IdClass c in classes)
      for (final IdMember m in c.members)
        if (m.usedIn.isEmpty) '${c.name}.${m.name}',
  ];
  if (unused.isNotEmpty) {
    stdout.writeln('Declared but not used by any widget: ${unused.join(', ')}');
  }
  if (tsPath != null) {
    File(tsPath).writeAsStringSync(_typescript(classes));
    stdout.writeln('$tsPath: written');
  }
}

// --- Model ------------------------------------------------------------------

class IdClass {
  IdClass(this.name, this.file);

  final String name;
  final String file;
  final List<IdMember> members = <IdMember>[];

  String get screen => _screens[name] ?? name;
}

class IdMember {
  IdMember({
    required this.name,
    required this.value,
    required this.isFamily,
    this.param,
    this.paramType,
    this.pattern,
  });

  final String name;

  /// The literal identifier, or for a family the Dart string literal body.
  final String value;
  final bool isFamily;
  final String? param;
  final String? paramType;

  /// For a family: how it reads in the inventory (`cart_item_<line id>`).
  final String? pattern;
  final List<String> usedIn = <String>[];

  /// A getter of the same class that builds this family, if any.
  String? viaGetter;
}

// --- Sources ----------------------------------------------------------------

Iterable<File> _walk(String root, bool Function(String) keep) sync* {
  final Directory dir = Directory(root);
  if (!dir.existsSync()) {
    return;
  }
  for (final FileSystemEntity e in dir.listSync(recursive: true)) {
    final String p = e.path;
    if (e is File &&
        p.endsWith('.dart') &&
        !p.contains('/build/') &&
        !p.contains('/.dart_tool/') &&
        keep(p)) {
      yield e;
    }
  }
}

Iterable<File> _idFiles() => <File>[
  ..._walk('packages/features', (String p) => p.endsWith('_semantic_ids.dart')),
  ..._walk(
    'packages/apps/market_app/lib',
    (String p) => p.endsWith('_semantic_ids.dart'),
  ),
];

Iterable<File> _widgetFiles() => <File>[
  ..._walk(
    'packages/features',
    (String p) => p.contains('/module/lib/') && !p.contains('/test/'),
  ),
  ..._walk('packages/apps/market_app/lib', (_) => true),
];

String _relative(String path) =>
    path.startsWith('./') ? path.substring(2) : path;

List<IdClass> _parse(File file) {
  final String source = file.readAsStringSync();
  final List<IdClass> result = <IdClass>[];
  final RegExp classStart = RegExp(
    r'^class (\w+SemanticIds) \{',
    multiLine: true,
  );
  for (final RegExpMatch c in classStart.allMatches(source)) {
    final int end = source.indexOf('\n}', c.end);
    final String body = source.substring(c.end, end);
    final IdClass idClass = IdClass(c.group(1)!, _relative(file.path));
    final RegExp member = RegExp(
      r"((?:[ ]*///[^\n]*\n)*)[ ]*static (?:const String (\w+)\s*=\s*'([^']*)'|String (\w+)\((\w+) (\w+)\)\s*=>\s*'([^']*)')",
    );
    for (final RegExpMatch m in member.allMatches(body)) {
      final String doc = m.group(1)!;
      if (m.group(2) != null) {
        idClass.members.add(
          IdMember(name: m.group(2)!, value: m.group(3)!, isFamily: false),
        );
      } else {
        final String literal = m.group(7)!;
        final String prefix = literal.substring(0, literal.indexOf(r'$'));
        final RegExpMatch? documented = RegExp(
          '`(${RegExp.escape(prefix)}[^`]*)`',
        ).firstMatch(doc);
        idClass.members.add(
          IdMember(
            name: m.group(4)!,
            value: literal,
            isFamily: true,
            paramType: m.group(5),
            param: m.group(6),
            pattern: documented?.group(1) ?? '$prefix<${m.group(6)}>',
          ),
        );
      }
    }
    for (final RegExpMatch g in RegExp(
      r'get (\w+)\s*=>([^;]*);',
    ).allMatches(body)) {
      for (final IdMember m in idClass.members) {
        if (m.isFamily && RegExp('\\b${m.name}\\(').hasMatch(g.group(2)!)) {
          m.viaGetter = g.group(1);
        }
      }
    }
    result.add(idClass);
  }
  return result;
}

// --- Screens, in the order a user meets them --------------------------------

const Map<String, String> _screens = <String, String>{
  'SplashSemanticIds': 'Splash',
  'OnboardingSemanticIds': 'Onboarding',
  'LoginSemanticIds': 'Login',
  'RegisterSemanticIds': 'Registro',
  'RecoverPasswordSemanticIds': 'Recuperar contraseña',
  'ShellSemanticIds': 'Navegación (shell)',
  'DashboardSemanticIds': 'Dashboard',
  'NotificationsSemanticIds': 'Notificaciones',
  'CatalogListSemanticIds': 'Catálogo',
  'ProductDetailSemanticIds': 'Detalle de producto',
  'ProductFormSemanticIds': 'Formulario de producto',
  'MyProductsSemanticIds': 'Mis productos',
  'FavoritesSemanticIds': 'Favoritos',
  'ReviewFormSemanticIds': 'Reseña',
  'CartSemanticIds': 'Carrito',
  'CheckoutSemanticIds': 'Checkout',
  'CheckoutSuccessSemanticIds': 'Compra confirmada',
  'OrdersListSemanticIds': 'Pedidos',
  'OrderDetailSemanticIds': 'Detalle de pedido',
  'ProfileSemanticIds': 'Perfil',
  'AddressesSemanticIds': 'Direcciones',
  'SettingsSemanticIds': 'Ajustes',
  'AboutSemanticIds': 'Acerca de',
};

int _order(String className) {
  final int i = _screens.keys.toList().indexOf(className);
  return i < 0 ? 1000 : i;
}

// --- "Elemento": the member name, read in Spanish ----------------------------

const Map<String, String> _types = <String, String>{
  'input': 'campo',
  'button': 'botón',
  'text': 'texto',
  'view': 'pantalla',
  'dialog': 'diálogo',
  'checkbox': 'casilla',
  'switch': 'interruptor',
  'list': 'lista',
  'sheet': 'hoja inferior',
  'slider': 'deslizador',
  'dropdown': 'desplegable',
  'selector': 'selector',
  'indicator': 'indicador',
  'carousel': 'carrusel',
  'image': 'imagen',
  'stepper': 'selector de cantidad',
  'item': 'item',
  'option': 'opción',
  'filter': 'filtro',
  'filters': 'filtros',
  'chip': 'chip',
  'card': 'tarjeta',
  'bar': 'barra',
  'rail': 'barra lateral',
  'page': 'página',
  'banner': 'aviso',
  'state': 'estado',
  'timeline': 'línea de tiempo',
  'star': 'estrella',
  'suggestion': 'sugerencia',
  'method': 'opción',
  'tab': 'pestaña',
};

const Map<String, String> _words = <String, String>{
  'go': 'ir',
  'to': 'a',
  'register': 'registro',
  'recover': 'recuperación',
  'password': 'contraseña',
  'email': 'correo',
  'toggle': 'alternar',
  'visibility': 'visibilidad',
  'error': 'error',
  'submit': 'enviar',
  'full': 'completo',
  'name': 'nombre',
  'phone': 'teléfono',
  'confirm': 'confirmar',
  'terms': 'términos',
  'step': 'paso',
  'send': 'enviar',
  'code': 'código',
  'demo': 'demo',
  'validate': 'validar',
  'new': 'nueva',
  'success': 'éxito',
  'loading': 'cargando',
  'retry': 'reintentar',
  'skip': 'omitir',
  'next': 'siguiente',
  'start': 'empezar',
  'mark': 'marcar',
  'all': 'todo',
  'read': 'leído',
  'language': 'idioma',
  'theme': 'tema',
  'currency': 'moneda',
  'see': 'ver',
  'again': 'de nuevo',
  'reset': 'restablecer',
  'data': 'datos',
  'wipe': 'borrar',
  'cancel': 'cancelar',
  'about': 'acerca de',
  'version': 'versión',
  'platform': 'plataforma',
  'navigation': 'navegación',
  'catalog': 'catálogo',
  'cart': 'carrito',
  'orders': 'pedidos',
  'profile': 'perfil',
  'greeting': 'saludo',
  'refresh': 'refrescar',
  'notifications': 'notificaciones',
  'logout': 'cerrar sesión',
  'category': 'categoría',
  'recent': 'recientes',
  'products': 'productos',
  'create': 'crear',
  'product': 'producto',
  'favorites': 'favoritos',
  'my': 'mis',
  'summary': 'resumen',
  'search': 'búsqueda',
  'price': 'precio',
  'range': 'rango',
  'only': 'solo',
  'in': 'en',
  'stock': 'stock',
  'sort': 'orden',
  'clear': 'limpiar',
  'results': 'resultados',
  'count': 'conteo',
  'empty': 'vacío',
  'condition': 'condición',
  'active': 'activo',
  'favorite': 'favorito',
  'share': 'compartir',
  'description': 'descripción',
  'seller': 'vendedor',
  'quantity': 'cantidad',
  'decrease': 'restar',
  'increase': 'sumar',
  'add': 'agregar',
  'own': 'propio',
  'notice': 'aviso',
  'edit': 'editar',
  'write': 'escribir',
  'review': 'reseña',
  'reviews': 'reseñas',
  'no': 'sin',
  'message': 'mensaje',
  'picker': 'elegir',
  'preview': 'vista previa',
  'save': 'guardar',
  'discard': 'descartar',
  'changes': 'cambios',
  'delete': 'eliminar',
  'status': 'estado',
  'move': 'mover',
  'rating': 'calificación',
  'comment': 'comentario',
  'removed': 'eliminado',
  'coupon': 'cupón',
  'apply': 'aplicar',
  'applied': 'aplicado',
  'remove': 'quitar',
  'subtotal': 'subtotal',
  'discount': 'descuento',
  'tax': 'impuesto',
  'total': 'total',
  'line': 'línea',
  'address': 'dirección',
  'prompt': 'indicación',
  'label': 'etiqueta',
  'line1': 'línea 1',
  'city': 'ciudad',
  'region': 'región',
  'notes': 'notas',
  'number': 'número',
  'holder': 'titular',
  'expiry': 'vencimiento',
  'cvv': 'cvv',
  'payment': 'pago',
  'back': 'atrás',
  'headline': 'titular',
  'order': 'pedido',
  'home': 'inicio',
  'date': 'fecha',
  'keep': 'mantener',
  'reorder': 'volver a pedir',
  'avatar': 'avatar',
  'current': 'actual',
  'account': 'cuenta',
  'second': 'segundo',
  'addresses': 'direcciones',
  'settings': 'ajustes',
  'set': 'marcar',
  'default': 'predeterminada',
  'title': 'título',
  'dashboard': 'dashboard',
  'item': 'item',
  'image': 'imagen',
  'card': 'tarjeta',
  'option': 'opción',
  'filter': 'filtro',
  'dialog': 'diálogo',
  'own_review': 'reseña propia',
  'onboarding': 'onboarding',
};

String _element(IdMember member) {
  if (member.name.contains('TogglePasswordVisibility') ||
      member.name == 'togglePasswordVisibilityButton') {
    return 'Mostrar/ocultar contraseña · botón';
  }
  // A dialog's buttons: `<dialog>ConfirmButton` / `<dialog>CancelButton`.
  for (final MapEntry<String, String> action in <String, String>{
    'ConfirmButton': 'Confirmar',
    'CancelButton': 'Cancelar',
    'KeepButton': 'Mantener',
  }.entries) {
    if (member.name.endsWith(action.key) && member.name != 'confirmButton') {
      final String dialog = member.name.substring(
        0,
        member.name.length - action.key.length,
      );
      return '${action.value} · diálogo '
          '${_element(IdMember(name: '${dialog}Dialog', value: '', isFamily: false)).split(' · ').first.toLowerCase()}';
    }
  }
  final List<String> tokens = member.name
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (Match m) => '${m[1]} ${m[2]}',
      )
      .toLowerCase()
      .split(' ');
  String? type;
  if (tokens.length > 1 && _types.containsKey(tokens.last)) {
    type = _types[tokens.removeLast()];
  } else if (tokens.length == 1 && _types.containsKey(tokens.single)) {
    return _capitalize(_types[tokens.single]!);
  }
  final String rest = tokens.map((String t) => _words[t] ?? t).join(' ');
  return type == null ? _capitalize(rest) : '${_capitalize(rest)} · $type';
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

// --- Markdown ---------------------------------------------------------------

String _markdown(List<IdClass> classes) {
  final StringBuffer out = StringBuffer()
    ..writeln(
      '<!-- Generado por packages/e2e_framework/tool/semantic_ids/inventory.dart. No editar a mano: `melos run semanticIdsInventory`. -->',
    )
    ..writeln()
    ..writeln('# Inventario de locators (semantics identifiers)')
    ..writeln()
    ..writeln(_intro)
    ..writeln()
    ..writeln('## Índice')
    ..writeln();
  for (final IdClass c in classes) {
    out.writeln('- [${c.screen}](#${_anchor(c.screen)}) — ${c.members.length}');
  }
  for (final IdClass c in classes) {
    out
      ..writeln()
      ..writeln('## ${c.screen}')
      ..writeln()
      ..writeln('Constantes: `${c.name}` en `${c.file}`.')
      ..writeln()
      ..writeln('| Pantalla | Elemento | Identifier | Archivo |')
      ..writeln('|---|---|---|---|');
    for (final IdMember m in c.members) {
      final String id = m.isFamily ? m.pattern! : m.value;
      final String files = m.usedIn.isEmpty
          ? '—'
          : m.usedIn
                .map((String f) => '`${f.replaceFirst('packages/', '')}`')
                .join('<br>');
      out.writeln('| ${c.screen} | ${_element(m)} | `$id` | $files |');
    }
  }
  return out.toString();
}

String _anchor(String title) =>
    title.toLowerCase().replaceAll(RegExp(r'[()]'), '').replaceAll(' ', '-');

const String _intro = '''
Cada elemento que una prueba necesita tiene un `Semantics(identifier: …)`. Ese
identifier aparece, según la plataforma, como:

| Plataforma | Atributo | Herramienta |
|---|---|---|
| Android | `resource-id` | Appium (`id`), Maestro (`id:`), `adb shell uiautomator dump` |
| iOS | `accessibilityIdentifier` | Appium (`accessibility id`), Maestro (`id:`), Accessibility Inspector |
| Web | `flt-semantics-identifier` | Playwright (`getByTestId` con `testIdAttribute: 'flt-semantics-identifier'`) |

En web, la semántica solo existe en un build con `--dart-define=ENABLE_SEMANTICS=true`
(`melos run buildWebQa`). Los builds de producción no la tienen.

## Convención

- `<pantalla>_<elemento>_<tipo>`, en inglés y snake_case. No depende del idioma ni del país.
- Los items de una lista llevan un dato estable del item (id, código), nunca su
  posición: `cart_item_<line id>`. Los `<…>` de la tabla son ese dato.
- Ningún identifier fijo empieza con el prefijo de una familia, así que
  `[flt-semantics-identifier^="cart_item_"]` cuenta solo las líneas del carrito.
- `<pantalla>_state_<loading|data|empty|error>` marca el estado de la pantalla:
  sirve para esperar a que termine de cargar.
- Los diálogos llevan `<id del diálogo>`, `<id>_confirm_button` y `<id>_cancel_button`.
- Las fuentes de verdad son las clases `*SemanticIds` de cada paquete `constants`.
  `semantic_ids_test.dart` (en `market_app/test/semantics_guards/`) falla si un
  identifier se repite, rompe la convención o se escribe como string suelto en un widget.

## Qué hay en cada nodo

- **Campos:** el identifier está en el nodo editable. En web es un
  `<flt-semantics>` y el `<input>` real es su hijo:
  `getByTestId('login_email_input').locator('input')`.
- **Botones, chips, pestañas y tarjetas tocables:** el identifier está en el nodo
  que recibe el tap y expone su estado (`enabled`, `selected`, `checked`). En web:
  `aria-disabled`, `aria-selected`, `aria-checked`.
- **Textos:** el texto es el contenido del nodo.
- **Tarjetas (`*_item_<id>`):** un solo nodo cuyo texto reúne lo que muestra la
  tarjeta. Los botones que tiene adentro conservan su propio identifier.
- **Montos (`*_total_text`, `*_subtotal_text`…):** solo el monto, sin su etiqueta.
- **Regiones** (listas, secciones, estados, diálogos, hojas): un nodo propio que
  contiene a sus hijos. Se buscan los elementos *dentro* de ellas.

## Limitaciones conocidas

- **Errores de cada campo** (validación bajo el input): forman parte del nodo del
  campo y no tienen identifier propio.
- **"Deshacer" del snackbar del carrito:** `SnackBarAction` recibe su texto como
  `String`, así que no hay dónde poner el identifier sin reemplazar el widget.
- **Flecha atrás del AppBar** (`BackButton`, en recuperar contraseña y checkout):
  sin identifier por la misma razón.
- **Botones con `Semantics(label, button)` previo:** el toggle de contraseña del
  login, la campana de notificaciones, favorito y compartir del detalle, y la
  tarjeta de producto del catálogo. El identifier está en ese `Semantics` (como pide
  la regla de no anidar otro), que ya formaba un nodo propio sobre el del botón.
  Tocar el centro del elemento funciona en todas las herramientas, pero ese nodo
  no expone la acción de tap. Es un defecto de accesibilidad previo: un lector de
  pantalla anuncia dos botones.
- **Línea de tiempo del pedido:** qué etapa se alcanzó solo se ve por el ícono y
  el peso de la fuente, no se expone a la accesibilidad.''';

// --- TypeScript mirror ------------------------------------------------------

String _typescript(List<IdClass> classes) {
  final StringBuffer out = StringBuffer()
    ..writeln('/**')
    ..writeln(
      ' * Semantics identifiers of the Market app, one object per screen.',
    )
    ..writeln(' *')
    ..writeln(' * GENERATED from the app repository by')
    ..writeln(
      ' * `packages/e2e_framework/tool/semantic_ids/inventory.dart --ts <this file>`',
    )
    ..writeln(
      ' * (`melos run semanticIdsInventory -- --ts …`). Do not edit by hand: change',
    )
    ..writeln(
      ' * the Dart `*SemanticIds` classes and regenerate, so both sides move together.',
    )
    ..writeln(' */')
    ..writeln()
    ..writeln(
      '/** Mirrors the Dart slug: lower case, runs of non [a-z0-9] become `_`. */',
    )
    ..writeln('function slug(text: string): string {')
    ..writeln(
      "  return text.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+\$/g, '');",
    )
    ..writeln('}');
  for (final IdClass c in classes) {
    final String name = '${c.name.replaceFirst('SemanticIds', '')}Ids';
    out
      ..writeln()
      ..writeln('/** ${c.screen} — `${c.name}`. */')
      ..writeln('export const $name = {');
    for (final IdMember m in c.members) {
      if (!m.isFamily) {
        out.writeln("  ${m.name}: '${m.value}',");
      } else {
        final String type = m.paramType == 'int' ? 'number' : 'string';
        final String template = m.value
            .replaceAllMapped(
              RegExp(r'\$\{([^}]*)\}'),
              (Match x) => '\${${x[1]!.replaceAll('_slug(', 'slug(')}}',
            )
            .replaceAllMapped(RegExp(r'\$(\w+)'), (Match x) => '\${${x[1]}}');
        out.writeln('  ${m.name}: (${m.param}: $type) => `$template`,');
      }
    }
    out.writeln('} as const;');
  }
  return out.toString();
}
