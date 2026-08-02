# Market — marketplace local de vehículos ligeros

Monorepo Flutter de referencia: un marketplace donde la misma persona compra y
vende (carros, motos, patinetas, bicicletas y camionetas). **Sin backend**: todo
vive en SQLite local y sobrevive al cierre de la app en Android, iOS y Web.

El repositorio es la entrega: micro-features desacoplados, dirección de
dependencias estricta, estado inmutable, inyección por overrides, i18n completo
y linting agresivo. Agregar un feature nuevo debería ser copiar la estructura de
uno existente.

---

## Arranque rápido

```bash
dart pub global activate melos 7.3.0
melos bs
melos run lint
```

```bash
cd packages/apps/market_app
flutter run -d chrome
flutter run -d android
flutter run -d ios
```

Usuarios de demostración (contraseña `Demo1234`):

| Correo | Rol en el seed |
|---|---|
| `ana@market.demo` | 5 publicaciones, 2 direcciones, 1 orden entregada |
| `bruno@market.demo` | 10 publicaciones |

---

## Stack

| Herramienta | Versión |
|---|---|
| Flutter | `3.41.9` (stable) |
| Dart SDK | `^3.11.5` |
| Melos | `7.3.0` |

Todas las dependencias de terceros están **fijadas sin caret** en cada
`pubspec.yaml` (reproducibilidad total). Las tres que el prompt dejó abiertas se
resolvieron con `flutter pub add` y quedaron fijadas así:

| Paquete | Versión | Nota |
|---|---|---|
| `easy_localization` | `3.0.8` | última estable de la línea 3.x |
| `go_router` | `17.3.0` | última estable compatible |
| `sqflite_common_ffi_web` | `1.1.1` | la 1.1.2 exige Flutter 3.44+, incompatible con 3.41.9 |

Única dependencia añadida fuera de la lista: **`flutter_web_plugins`** (SDK de
Flutter, no es un tercero) para activar rutas reales en web —
ver [Deep links](#deep-links).

---

## Mapa de paquetes

```
packages/
├── apps/market_app/                 shell: wiring (router, DI, i18n, arranque)
├── development/lint/                analysis_options compartido
├── shared/                          lógica pura, CERO widgets
│   ├── typing/                      ViewModel base, Clock, IdGenerator, ViewStatus
│   ├── database/                    conexión, esquema, migraciones, seed, DAO base
│   ├── navigator/                   AppRoute, NavigationManager, BootstrapGate, deep links
│   └── utilities/                   formatters, validators, logger, guards, ImageStorage
├── ui/
│   ├── design_system/               tokens + temas claro/oscuro + primitivos
│   └── components/packages/         product_card, quantity_stepper, rating_stars,
│                                    price_tag, filter_chip_bar, status_badge,
│                                    stepper_header, empty_state
└── features/
    ├── generic/                     app_cross, authentication, dashboard, profile
    └── core/                        catalog, cart, orders
```

Cada feature son tres paquetes:

| Sub-paquete | Contenido | Depende de |
|---|---|---|
| `constants` | keys de widget, rutas, límites | nada |
| `typing` | contrato público: modelos, enums, interfaces, providers sin implementar | `constants` |
| `module` | implementación privada: DAO, service, estado, UI | `constants`, `typing` |

### Dirección de dependencias

```
apps  →  features  →  shared
 │         │            ↑
 │         └────→  ui ──┘
 └──────────────────────┘
```

- `features/` importa de `shared/`, `ui/` y del **`typing/` de otros features**,
  nunca de su `module/`.
- `shared/` y `ui/` no importan jamás de `features/` ni de `apps/`.
- `design_system` no depende de ningún paquete interno.
- La navegación entre features usa rutas (strings) o el `typing/` ajeno, nunca
  el módulo del otro feature.

---

## Arquitectura

### Estado (Riverpod 2.6.1)

Cada sub-estado es **una sola librería** con `part`s en orden alfabético:

```dart
library com.demo.market.catalog.core.state.list;
part 'controller.dart';
part 'provider.dart';
part 'state.dart';
```

El estado es una clase plana inmutable (`copyWith`, `==`, `hashCode`,
`toString`), escrita a mano: sin `freezed`, para que el ejemplo se lea sin
codegen. Nunca se muta en sitio; siempre `state = state.copyWith(...)`.

Los controllers extienden `ViewModel<T>` (en `shared/typing`), que aporta:

- `postInit()` — **síncrono**, resuelve dependencias (`service`,
  `navigatorNotifier`) antes de que nadie pueda llamar al controller.
- `runPostBuild(action)` — lanza la carga inicial en el microtask siguiente.
  Riverpod prohíbe escribir `state` mientras `build()` corre, y llamar la carga
  en línea dejaría los campos `late` sin asignar si la vista invoca un método de
  inmediato (bug real que apareció al abrir un deep link).
- `mountedKey` — token que se captura antes de un `await` para detectar
  disposición a mitad de vuelo.

### Inyección de dependencias

El provider del servicio se **declara** en `typing/` lanzando
`UnimplementedError` y se **sobreescribe** en `module/core/service/provider.dart`.
El shell junta todos los overrides en `lib/di/app_overrides.dart`; es el único
lugar donde infraestructura y features se conocen.

### Datos

`DAO → Service → Controller → Vista`. El DAO habla SQL crudo y devuelve
`Map<String, Object?>`; el service convierte filas ↔ modelos y aplica reglas de
negocio; el controller orquesta y maneja errores. **Ninguna vista ejecuta SQL.**

Toda escritura multi-tabla va en `transaction`. Los dos casos críticos:

- **Checkout**: crea `orders` + `order_items` (con snapshot de nombre y precio),
  descuenta stock, vacía el carrito y genera la notificación — todo o nada.
- **Cancelar orden**: cambia estado, restituye stock y notifica, en una sola
  transacción.

Las contraseñas se guardan como `sha256(salt + password)` con salt por usuario.
En producción sería un KDF con costo (bcrypt/argon2) y almacenamiento seguro;
está comentado en `PasswordHasher`.

Los textos de `notifications` se guardan como **claves i18n** con sus argumentos
en el `payload` JSON, nunca como texto ya traducido.

---

## Multiplataforma

Las diferencias nativas se resuelven detrás de una abstracción y se documentan
en un único archivo por tema:

| Tema | Archivo | Android / iOS | Web |
|---|---|---|---|
| Base de datos | `shared/database/.../database_factory_resolver.dart` | `sqflite` + `getDatabasesPath()` | `sqflite_common_ffi_web` (wasm + IndexedDB) |
| Imágenes | `shared/utilities/.../image_storage.dart` | archivo copiado al directorio de la app, se guarda la ruta | data URI base64 en la propia fila |
| URLs | `shared/utilities/.../url_strategy.dart` | no aplica (scheme `market://`) | `usePathUrlStrategy()` para rutas reales |
| Guards | `shared/utilities/.../platform_guard.dart` | — | — |

`dart:io` solo aparece detrás de un import condicional; ningún feature lo toca.

Configuración de plataforma: Android `minSdk 23` e intent-filter para `market://`;
iOS deployment target `13.0`, `CFBundleURLTypes` y permisos de galería/cámara con
textos en español. Los assets wasm de web (`sqlite3.wasm`, `sqflite_sw.js`) se
generan con:

```bash
dart run sqflite_common_ffi_web:setup
```

### Layout

Un mismo controller sirve mobile y web; solo cambia la presentación.
`AppScaffold` aporta SafeArea, padding y ancho máximo de 1200 px. El shell de
navegación usa barra inferior por debajo de 768 px y rail lateral por encima,
preservando el estado de cada pestaña con `StatefulShellRoute.indexedStack`.

---

## Deep links

El scheme es `market://` y las rutas son nombradas, con parámetros de path
(nunca datos de negocio en query strings).

```bash
# Web (requiere que el host sirva index.html en rutas desconocidas)
open http://localhost:8080/catalog/detail/product_car_001

# Android
adb shell am start -a android.intent.action.VIEW \
  -d "market://catalog/detail/product_car_001" com.demo.market_app

# iOS
xcrun simctl openurl booted "market://catalog/detail/product_car_001"
```

Dos piezas lo hacen funcionar:

1. **`usePathUrlStrategy()`** en web. Por defecto Flutter usa URLs con hash
   (`/#/catalog`), así que la ruta del path nunca llegaba al router.
2. **`BootstrapGate`** (`shared/navigator`). En arranque en frío el router se
   evalúa antes de que existan la base de datos y la sesión, así que el redirect
   de sesión se llevaría el deep link a login y lo perdería. La compuerta aparca
   la ubicación pedida, manda al splash, y el splash (o el login que le sigue)
   la retoma al terminar el bootstrap.

Una ruta a un recurso inexistente muestra la vista de "no encontrado"
(`shell_not_found_view`) o el estado `empty` de la vista, nunca una pantalla en
blanco.

---

## Flags de arranque

```bash
flutter run -d chrome --dart-define=SEED_MODE=empty
flutter run -d chrome --dart-define=FAST_ANIMATIONS=true
```

| Flag | Valores | Efecto |
|---|---|---|
| `SEED_MODE` | `demo` (default) / `empty` | BD con datos semilla deterministas o BD vacía para recorrer los estados sin datos |
| `FAST_ANIMATIONS` | `true` / ausente | todas las duraciones de `AppDurations` pasan a `Duration.zero` |

Se leen en un único archivo (`lib/config/app_config.dart`) y se propagan por
overrides.

---

## Determinismo

1. **Semilla fija**: ids literales (`user_demo_001`, `cat_car`,
   `product_car_001`…), precios y fechas constantes. 2 usuarios, 5 categorías,
   15 productos, 3 cupones (`DEMO10` válido, `PAST20` vencido, `FROZEN15`
   inactivo), 2 direcciones y 1 orden histórica entregada.
2. **Reloj inyectado**: `Clock` + `clockProvider`. `DateTime.now()` solo se
   nombra dentro de ese provider.
3. **Ids inyectados**: `IdGenerator` detrás de provider (`UuidIdGenerator` por
   defecto), sustituible por uno secuencial.
4. **Orden estable**: todo `SELECT` que alimente una lista lleva `ORDER BY`
   explícito con desempate por `id`.
5. **Sin trabajo oculto**: ningún timer periódico ni animación infinita; los
   shimmer solo existen mientras la vista está en estado `loading`.
6. **Reset desde la app**: Ajustes ofrece "restablecer datos de demostración"
   (`resetToSeed`) y "borrar todos mis datos" (`wipe`), ambos con confirmación.

---

## Identificadores de widget

Las keys son **contrato, no etiqueta**: no dependen del idioma, del tema ni de
la plataforma, y no cambian cuando cambia el copy. Se declaran en el
`constants/` de cada feature y las vistas las referencian por constante.

```
<feature>_<vista>_view       raíz de la vista
<elemento>_<tipo>            elemento concreto
<elemento>_item_<id>         ítem dinámico (id de entidad, nunca el índice)
<vista>_state_<estado>       raíz de loading / data / empty / error
```

Los elementos con significado para el usuario llevan además `Semantics(label:)`
traducido.

---

## Internacionalización

`easy_localization` con `es` (default) y `en`, ambos completos. Cada feature
declara su mapa en `module/lib/ui/languages.dart` y el shell los fusiona en
`MarketTranslationsLoader` — las traducciones viven en código, no en assets
JSON. Convención de claves: `feature.pantalla.elemento`, mínimo tres niveles.

Cambiar el idioma en Ajustes actualiza toda la app sin reiniciar y no altera
ningún `Key`.

---

## Comandos de Melos

```bash
melos bs                    # bootstrap
melos clean && melos bs     # arranque limpio
melos run lint              # flutter analyze --no-fatal-infos
melos run dartFormat        # dart format . --line-length 80
melos run dartFix           # dart fix --apply
melos run pubGet
melos run rmlock
melos run rmOverrides
```

---

## Flujos implementados

Los 16 flujos del catálogo están implementados: F01 splash · F02 onboarding ·
F03 registro · F04 login y sesión · F05 recuperación de contraseña ·
F06 dashboard · F07 catálogo con búsqueda, filtros y scroll infinito ·
F08 detalle de producto · F09 publicar producto · F10 mis publicaciones ·
F11 carrito con cupones · F12 checkout multipaso · F13 órdenes con línea de
tiempo, cancelación y recompra · F14 favoritos · F15 reseñas · F16 perfil,
direcciones, notificaciones y ajustes.

---

## Decisiones técnicas

- **Sin `freezed` ni `json_serializable`.** Los modelos se escriben a mano para
  que el ejemplo sea autoexplicativo y no dependa de codegen.
- **`ViewStatus` en vez de banderas sueltas.** Un enum con getters booleanos
  (`isLoading`, `isData`, `isEmpty`, `isError`) permite que la vista resuelva sus
  cuatro estados con un `switch` exhaustivo y que el analizador detecte los
  casos faltantes.
- **`runPostBuild` en el `ViewModel` base.** Ver [Estado](#estado-riverpod-261).
- **Borrado lógico de publicaciones.** `status = DELETED` las saca del catálogo
  pero conserva los snapshots en las órdenes históricas.
- **Moneda de visualización con factor fijo.** Cambiar a USD solo cambia el
  render; los precios se almacenan siempre en COP y la conversión es una
  constante (no hay fuente de tasas en una app offline).
- **El código de recuperación es determinista**, derivado del correo, y se
  muestra en un banner de demo. En producción sería aleatorio, con expiración y
  enviado por correo.
- **Los datos de tarjeta nunca se persisten**: se validan en el paso 2 del
  checkout y solo el método elegido llega a la base de datos.

## Limitaciones conocidas

- **Verificación por plataforma.**
  - **Web**: recorrido completo — login, dashboard, catálogo, detalle, carrito
    con cupones (válido, vencido), checkout de tres pasos, orden creada con
    descuento de stock y deep links en arranque en frío.
  - **Android**: verificado en un dispositivo físico (Samsung SM-A315G,
    Android 12): splash, onboarding, registro, login, dashboard con barra
    inferior, detalle de producto y el deep link
    `adb shell am start -d "market://catalog/detail/product_car_001"`.
  - **iOS**: verificado en el simulador de iPhone 17 (Xcode 26.6): onboarding,
    login, dashboard con barra inferior, detalle de producto, el deep link
    `xcrun simctl openurl booted "market://catalog/detail/product_car_001"` y
    **persistencia** — un favorito marcado antes de reiniciar la app seguía ahí
    después. El simulador corre en apariencia clara, así que esta pasada validó
    además el tema claro (Android y Web se recorrieron en oscuro).
- **Deep links en web** requieren que el host sirva `index.html` para rutas
  desconocidas (fallback SPA). Sin eso, un `F5` sobre `/catalog/detail/x`
  devuelve 404 del servidor, no de la app.
- **Sin pruebas automatizadas**: el alcance pedido excluye explícitamente tests.
  El determinismo y las keys estables quedan disponibles para agregarlas.
- **Las imágenes en web viven en la fila** como data URI; con muchas imágenes
  grandes conviene mover a IndexedDB por separado.
