<!-- Generado por packages/e2e_framework/tool/semantic_ids/inventory.dart. No editar a mano: `melos run semanticIdsInventory`. -->

# Inventario de locators (semantics identifiers)

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
  el peso de la fuente, no se expone a la accesibilidad.

## Índice

- [Splash](#splash) — 4
- [Onboarding](#onboarding) — 5
- [Login](#login) — 9
- [Registro](#registro) — 12
- [Recuperar contraseña](#recuperar-contraseña) — 13
- [Navegación (shell)](#navegación-shell) — 7
- [Dashboard](#dashboard) — 20
- [Notificaciones](#notificaciones) — 6
- [Catálogo](#catálogo) — 21
- [Detalle de producto](#detalle-de-producto) — 25
- [Formulario de producto](#formulario-de-producto) — 19
- [Mis productos](#mis-productos) — 17
- [Favoritos](#favoritos) — 10
- [Reseña](#reseña) — 9
- [Carrito](#carrito) — 28
- [Checkout](#checkout) — 31
- [Compra confirmada](#compra-confirmada) — 5
- [Pedidos](#pedidos) — 8
- [Detalle de pedido](#detalle-de-pedido) — 20
- [Perfil](#perfil) — 34
- [Direcciones](#direcciones) — 20
- [Ajustes](#ajustes) — 19
- [Acerca de](#acerca-de) — 4

## Splash

Constantes: `SplashSemanticIds` en `packages/features/generic/app_cross/constants/lib/app_cross_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Splash | Pantalla | `splash_view` | `features/generic/app_cross/module/lib/ui/views/splash/splash_view.dart` |
| Splash | Cargando · texto | `splash_loading_text` | `features/generic/app_cross/module/lib/ui/views/splash/splash_view.dart` |
| Splash | Error · texto | `splash_error_text` | `features/generic/app_cross/module/lib/ui/views/splash/splash_error.dart` |
| Splash | Reintentar · botón | `splash_retry_button` | `features/generic/app_cross/module/lib/ui/views/splash/splash_error.dart` |

## Onboarding

Constantes: `OnboardingSemanticIds` en `packages/features/generic/app_cross/constants/lib/app_cross_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Onboarding | Pantalla | `onboarding_view` | `features/generic/app_cross/module/lib/ui/views/onboarding/onboarding_view.dart` |
| Onboarding | Omitir · botón | `onboarding_skip_button` | `features/generic/app_cross/module/lib/ui/views/onboarding/onboarding_view.dart` |
| Onboarding | Siguiente · botón | `onboarding_next_button` | `features/generic/app_cross/module/lib/ui/views/onboarding/onboarding_view.dart` |
| Onboarding | Empezar · botón | `onboarding_start_button` | `features/generic/app_cross/module/lib/ui/views/onboarding/onboarding_view.dart` |
| Onboarding | Página | `onboarding_page_<n>` | `features/generic/app_cross/module/lib/ui/views/onboarding/onboarding_view.dart` |

## Login

Constantes: `LoginSemanticIds` en `packages/features/generic/authentication/constants/lib/authentication_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Login | Pantalla | `login_view` | `features/generic/authentication/module/lib/ui/views/login/login_view.dart` |
| Login | Título · texto | `login_title_text` | `features/generic/authentication/module/lib/ui/views/login/login_view.dart` |
| Login | Correo · campo | `login_email_input` | `features/generic/authentication/module/lib/ui/views/login/login_form.dart` |
| Login | Contraseña · campo | `login_password_input` | `features/generic/authentication/module/lib/ui/views/login/login_form.dart` |
| Login | Mostrar/ocultar contraseña · botón | `login_toggle_password_visibility_button` | `features/generic/authentication/module/lib/ui/views/login/login_form.dart` |
| Login | Error · texto | `login_error_text` | `features/generic/authentication/module/lib/ui/views/login/login_form.dart` |
| Login | Enviar · botón | `login_submit_button` | `features/generic/authentication/module/lib/ui/views/login/login_form.dart` |
| Login | Ir a registro · botón | `login_go_to_register_button` | `features/generic/authentication/module/lib/ui/views/login/login_form.dart` |
| Login | Ir a recuperación contraseña · botón | `login_go_to_recover_password_button` | `features/generic/authentication/module/lib/ui/views/login/login_form.dart` |

## Registro

Constantes: `RegisterSemanticIds` en `packages/features/generic/authentication/constants/lib/authentication_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Registro | Pantalla | `register_view` | `features/generic/authentication/module/lib/ui/views/register/register_view.dart` |
| Registro | Título · texto | `register_title_text` | `features/generic/authentication/module/lib/ui/views/register/register_view.dart` |
| Registro | Completo nombre · campo | `register_full_name_input` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Correo · campo | `register_email_input` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Teléfono · campo | `register_phone_input` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Contraseña · campo | `register_password_input` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Mostrar/ocultar contraseña · botón | `register_toggle_password_visibility_button` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Confirmar contraseña · campo | `register_confirm_password_input` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Términos · casilla | `register_terms_checkbox` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Error · texto | `register_error_text` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Enviar · botón | `register_submit_button` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |
| Registro | Ir a login · botón | `register_go_to_login_button` | `features/generic/authentication/module/lib/ui/views/register/register_form.dart` |

## Recuperar contraseña

Constantes: `RecoverPasswordSemanticIds` en `packages/features/generic/authentication/constants/lib/authentication_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Recuperar contraseña | Pantalla | `recover_password_view` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_password_view.dart` |
| Recuperar contraseña | Título · texto | `recover_password_title_text` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_password_view.dart` |
| Recuperar contraseña | Paso · indicador | `recover_step_indicator` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_password_view.dart` |
| Recuperar contraseña | Error · texto | `recover_error_text` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_password_view.dart` |
| Recuperar contraseña | Correo · campo | `recover_email_input` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_email.dart` |
| Recuperar contraseña | Enviar código · botón | `recover_send_code_button` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_email.dart` |
| Recuperar contraseña | Demo código · texto | `recover_demo_code_text` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_code.dart` |
| Recuperar contraseña | Código · campo | `recover_code_input` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_code.dart` |
| Recuperar contraseña | Validar código · botón | `recover_validate_code_button` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_code.dart` |
| Recuperar contraseña | Nueva contraseña · campo | `recover_new_password_input` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_password.dart` |
| Recuperar contraseña | Confirmar nueva contraseña · campo | `recover_confirm_new_password_input` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_password.dart` |
| Recuperar contraseña | Enviar · botón | `recover_submit_button` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_step_password.dart` |
| Recuperar contraseña | Éxito · texto | `recover_success_text` | `features/generic/authentication/module/lib/ui/views/recover_password/recover_password_view.dart` |

## Navegación (shell)

Constantes: `ShellSemanticIds` en `packages/apps/market_app/lib/shell_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Navegación (shell) | Navegación · barra | `shell_navigation_bar` | `apps/market_app/lib/router/app_navigation_shell.dart` |
| Navegación (shell) | Navegación · barra lateral | `shell_navigation_rail` | `apps/market_app/lib/router/app_navigation_shell.dart` |
| Navegación (shell) | Tab dashboard | `shell_tab_dashboard` | `apps/market_app/lib/router/app_navigation_shell.dart` |
| Navegación (shell) | Tab catálogo | `shell_tab_catalog` | `apps/market_app/lib/router/app_navigation_shell.dart` |
| Navegación (shell) | Tab carrito | `shell_tab_cart` | `apps/market_app/lib/router/app_navigation_shell.dart` |
| Navegación (shell) | Tab pedidos | `shell_tab_orders` | `apps/market_app/lib/router/app_navigation_shell.dart` |
| Navegación (shell) | Tab perfil | `shell_tab_profile` | `apps/market_app/lib/router/app_navigation_shell.dart` |

## Dashboard

Constantes: `DashboardSemanticIds` en `packages/features/generic/dashboard/constants/lib/dashboard_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Dashboard | Pantalla | `dashboard_view` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Saludo · texto | `dashboard_greeting_text` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Refrescar · botón | `dashboard_refresh_button` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Notificaciones · botón | `dashboard_notifications_button` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Cerrar sesión · botón | `dashboard_logout_button` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Cerrar sesión · diálogo | `dashboard_logout_dialog` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Confirmar · diálogo cerrar sesión | `dashboard_logout_dialog_confirm_button` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Cancelar · diálogo cerrar sesión | `dashboard_logout_dialog_cancel_button` | `features/generic/dashboard/module/lib/ui/views/home/home_view.dart` |
| Dashboard | Categoría · carrusel | `dashboard_category_carousel` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Recientes productos · carrusel | `dashboard_recent_products_carousel` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Ir a catálogo · botón | `dashboard_go_to_catalog_button` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Ir a crear producto · botón | `dashboard_go_to_create_product_button` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Ir a carrito · botón | `dashboard_go_to_cart_button` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Ir a favoritos · botón | `dashboard_go_to_favorites_button` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Ir a mis productos · botón | `dashboard_go_to_my_products_button` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Reintentar · botón | `dashboard_retry_button` | `features/generic/dashboard/module/lib/ui/views/home/home_error.dart` |
| Dashboard | Estado | `dashboard_state_<loading|data|empty|error>` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart`<br>`features/generic/dashboard/module/lib/ui/views/home/home_empty.dart`<br>`features/generic/dashboard/module/lib/ui/views/home/home_error.dart`<br>`features/generic/dashboard/module/lib/ui/views/home/home_shimmer.dart` |
| Dashboard | Resumen · tarjeta | `dashboard_summary_card_<active_products|cart_items|cart_total|month_orders>` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Categoría · item | `dashboard_category_item_<category id>` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |
| Dashboard | Recientes · item | `dashboard_recent_item_<product id>` | `features/generic/dashboard/module/lib/ui/views/home/home_data.dart` |

## Notificaciones

Constantes: `NotificationsSemanticIds` en `packages/features/generic/app_cross/constants/lib/app_cross_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Notificaciones | Pantalla | `notifications_view` | `features/generic/app_cross/module/lib/ui/views/notifications/notifications_view.dart` |
| Notificaciones | Título · texto | `notifications_title_text` | `features/generic/app_cross/module/lib/ui/views/notifications/notifications_view.dart` |
| Notificaciones | Marcar todo leído · botón | `notifications_mark_all_read_button` | `features/generic/app_cross/module/lib/ui/views/notifications/notifications_view.dart` |
| Notificaciones | Reintentar · botón | `notifications_retry_button` | `features/generic/app_cross/module/lib/ui/views/notifications/notifications_error.dart` |
| Notificaciones | Estado | `notifications_state_<loading|data|empty|error>` | `features/generic/app_cross/module/lib/ui/views/notifications/notifications_data.dart`<br>`features/generic/app_cross/module/lib/ui/views/notifications/notifications_empty.dart`<br>`features/generic/app_cross/module/lib/ui/views/notifications/notifications_error.dart`<br>`features/generic/app_cross/module/lib/ui/views/notifications/notifications_shimmer.dart` |
| Notificaciones | Item | `notifications_item_<id>` | `features/generic/app_cross/module/lib/ui/views/notifications/notifications_data.dart` |

## Catálogo

Constantes: `CatalogListSemanticIds` en `packages/features/core/catalog/constants/lib/catalog_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Catálogo | Pantalla | `catalog_list_view` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Título · texto | `catalog_list_title_text` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Búsqueda · campo | `catalog_search_input` | `features/core/catalog/module/lib/ui/views/list/list_search_bar.dart` |
| Catálogo | Filtro · botón | `catalog_filter_button` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Filtro · hoja inferior | `catalog_filter_sheet` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Precio rango · deslizador | `catalog_price_range_slider` | `features/core/catalog/module/lib/ui/views/list/list_filter_sheet.dart` |
| Catálogo | Solo en stock · interruptor | `catalog_only_in_stock_switch` | `features/core/catalog/module/lib/ui/views/list/list_filter_sheet.dart` |
| Catálogo | Orden · desplegable | `catalog_sort_dropdown` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Limpiar filters · botón | `catalog_clear_filters_button` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Resultados conteo · texto | `catalog_results_count_text` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Productos · lista | `catalog_products_list` | `features/core/catalog/module/lib/ui/views/list/list_data.dart` |
| Catálogo | Vacío limpiar filters · botón | `catalog_empty_clear_filters_button` | `features/core/catalog/module/lib/ui/views/list/list_empty.dart` |
| Catálogo | Reintentar · botón | `catalog_retry_button` | `features/core/catalog/module/lib/ui/views/list/list_error.dart` |
| Catálogo | Estado | `catalog_list_state_<loading|data|empty|error>` | `features/core/catalog/module/lib/ui/views/list/list_data.dart`<br>`features/core/catalog/module/lib/ui/views/list/list_empty.dart`<br>`features/core/catalog/module/lib/ui/views/list/list_error.dart`<br>`features/core/catalog/module/lib/ui/views/list/list_shimmer.dart` |
| Catálogo | Búsqueda · sugerencia | `catalog_search_suggestion_<term>` | `features/core/catalog/module/lib/ui/views/list/list_search_bar.dart` |
| Catálogo | Categoría · filtro | `catalog_category_filter_<category code>` | `features/core/catalog/module/lib/ui/views/list/list_filter_sheet.dart` |
| Catálogo | Condición · filtro | `catalog_condition_filter_<condition>` | `features/core/catalog/module/lib/ui/views/list/list_filter_sheet.dart` |
| Catálogo | Orden · opción | `catalog_sort_option_<sort>` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Activo filtro · chip | `catalog_active_filter_chip_<category id|condition|price|stock>` | `features/core/catalog/module/lib/ui/views/list/list_view.dart` |
| Catálogo | Producto · item | `catalog_product_item_<product id>` | `features/core/catalog/module/lib/ui/views/list/list_data.dart` |
| Catálogo | Producto favorito · botón | `catalog_product_favorite_button_<product id>` | `features/core/catalog/module/lib/ui/views/list/list_data.dart` |

## Detalle de producto

Constantes: `ProductDetailSemanticIds` en `packages/features/core/catalog/constants/lib/catalog_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Detalle de producto | Pantalla | `product_detail_view` | `features/core/catalog/module/lib/ui/views/detail/detail_view.dart` |
| Detalle de producto | Título · texto | `product_detail_title_text` | `features/core/catalog/module/lib/ui/views/detail/detail_view.dart` |
| Detalle de producto | Imagen | `product_detail_image` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Nombre · texto | `product_detail_name_text` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Favorito alternar · botón | `product_detail_favorite_toggle_button` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Compartir · botón | `product_detail_share_button` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Precio · texto | `product_detail_price_text` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Stock · texto | `product_detail_stock_text` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Descripción · texto | `product_detail_description_text` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Vendedor · texto | `product_detail_seller_text` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Cantidad · selector de cantidad | `product_detail_quantity_stepper` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Cantidad restar · botón | `product_detail_quantity_decrease_button` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Cantidad sumar · botón | `product_detail_quantity_increase_button` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Cantidad · texto | `product_detail_quantity_text` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Agregar a carrito · botón | `product_detail_add_to_cart_button` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Propio producto aviso · texto | `product_detail_own_product_notice_text` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Editar · botón | `product_detail_edit_button` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de producto | Escribir reseña · botón | `product_detail_write_review_button` | `features/core/catalog/module/lib/ui/views/detail/detail_reviews.dart` |
| Detalle de producto | Editar propio reseña · botón | `product_detail_edit_own_review_button` | `features/core/catalog/module/lib/ui/views/detail/detail_reviews.dart` |
| Detalle de producto | Sin reseñas · texto | `product_detail_no_reviews_text` | `features/core/catalog/module/lib/ui/views/detail/detail_reviews.dart` |
| Detalle de producto | Reseñas · lista | `product_detail_reviews_list` | `features/core/catalog/module/lib/ui/views/detail/detail_reviews.dart` |
| Detalle de producto | Mensaje · texto | `product_detail_message_text` | `features/core/catalog/module/lib/ui/views/detail/detail_view.dart` |
| Detalle de producto | Reintentar · botón | `product_detail_retry_button` | `features/core/catalog/module/lib/ui/views/detail/detail_error.dart` |
| Detalle de producto | Estado | `product_detail_state_<loading|data|empty|error>` | `features/core/catalog/module/lib/ui/views/detail/detail_data.dart`<br>`features/core/catalog/module/lib/ui/views/detail/detail_empty.dart`<br>`features/core/catalog/module/lib/ui/views/detail/detail_error.dart`<br>`features/core/catalog/module/lib/ui/views/detail/detail_shimmer.dart` |
| Detalle de producto | Reseña · item | `product_detail_review_item_<review id>` | `features/core/catalog/module/lib/ui/views/detail/detail_reviews.dart` |

## Formulario de producto

Constantes: `ProductFormSemanticIds` en `packages/features/core/catalog/constants/lib/catalog_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Formulario de producto | Pantalla | `product_form_view` | `features/core/catalog/module/lib/ui/views/form/form_view.dart` |
| Formulario de producto | Título · texto | `product_form_title_text` | `features/core/catalog/module/lib/ui/views/form/form_view.dart` |
| Formulario de producto | Nombre · campo | `product_form_name_input` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Descripción · campo | `product_form_description_input` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Precio · campo | `product_form_price_input` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Stock · campo | `product_form_stock_input` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Categoría · desplegable | `product_form_category_dropdown` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Condición · selector | `product_form_condition_selector` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Imagen vista previa | `product_form_image_preview` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Imagen elegir · botón | `product_form_image_picker_button` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Error · texto | `product_form_error_text` | `features/core/catalog/module/lib/ui/views/form/form_body.dart` |
| Formulario de producto | Guardar · botón | `product_form_save_button` | `features/core/catalog/module/lib/ui/views/form/form_body.dart` |
| Formulario de producto | Descartar cambios · diálogo | `product_form_discard_changes_dialog` | `features/core/catalog/module/lib/ui/views/form/form_view.dart` |
| Formulario de producto | Confirmar · diálogo descartar cambios | `product_form_discard_changes_dialog_confirm_button` | `features/core/catalog/module/lib/ui/views/form/form_view.dart` |
| Formulario de producto | Cancelar · diálogo descartar cambios | `product_form_discard_changes_dialog_cancel_button` | `features/core/catalog/module/lib/ui/views/form/form_view.dart` |
| Formulario de producto | Reintentar · botón | `product_form_retry_button` | `features/core/catalog/module/lib/ui/views/form/form_view.dart` |
| Formulario de producto | Estado | `product_form_state_<loading|data|empty|error>` | `features/core/catalog/module/lib/ui/views/form/form_view.dart` |
| Formulario de producto | Categoría · opción | `product_form_category_option_<category id>` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |
| Formulario de producto | Condición · opción | `product_form_condition_option_<condition>` | `features/core/catalog/module/lib/ui/views/form/form_fields.dart` |

## Mis productos

Constantes: `MyProductsSemanticIds` en `packages/features/core/catalog/constants/lib/catalog_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Mis productos | Pantalla | `my_products_view` | `features/core/catalog/module/lib/ui/views/my_products/my_products_view.dart` |
| Mis productos | Título · texto | `my_products_title_text` | `features/core/catalog/module/lib/ui/views/my_products/my_products_view.dart` |
| Mis productos | Crear · botón | `my_products_create_button` | `features/core/catalog/module/lib/ui/views/my_products/my_products_view.dart` |
| Mis productos | Confirmar eliminar · diálogo | `my_products_confirm_delete_dialog` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Confirmar · diálogo confirmar eliminar | `my_products_confirm_delete_dialog_confirm_button` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Cancelar · diálogo confirmar eliminar | `my_products_confirm_delete_dialog_cancel_button` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Vacío crear · botón | `my_products_empty_create_button` | `features/core/catalog/module/lib/ui/views/my_products/my_products_empty.dart` |
| Mis productos | Reintentar · botón | `my_products_retry_button` | `features/core/catalog/module/lib/ui/views/my_products/my_products_error.dart` |
| Mis productos | Estado | `my_products_state_<loading|data|empty|error>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart`<br>`features/core/catalog/module/lib/ui/views/my_products/my_products_empty.dart`<br>`features/core/catalog/module/lib/ui/views/my_products/my_products_error.dart`<br>`features/core/catalog/module/lib/ui/views/my_products/my_products_shimmer.dart` |
| Mis productos | Item | `my_products_item_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Stock · campo | `my_products_stock_input_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Stock · texto | `my_products_stock_text_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Stock restar · botón | `my_products_stock_decrease_button_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Stock sumar · botón | `my_products_stock_increase_button_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Editar · botón | `my_products_edit_button_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Alternar estado · botón | `my_products_toggle_status_button_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |
| Mis productos | Eliminar · botón | `my_products_delete_button_<product id>` | `features/core/catalog/module/lib/ui/views/my_products/my_products_data.dart` |

## Favoritos

Constantes: `FavoritesSemanticIds` en `packages/features/core/catalog/constants/lib/catalog_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Favoritos | Pantalla | `favorites_view` | `features/core/catalog/module/lib/ui/views/favorites/favorites_view.dart` |
| Favoritos | Título · texto | `favorites_title_text` | `features/core/catalog/module/lib/ui/views/favorites/favorites_view.dart` |
| Favoritos | Mover todo a carrito · botón | `favorites_move_all_to_cart_button` | `features/core/catalog/module/lib/ui/views/favorites/favorites_view.dart` |
| Favoritos | Mensaje · texto | `favorites_message_text` | `features/core/catalog/module/lib/ui/views/favorites/favorites_view.dart` |
| Favoritos | Reintentar · botón | `favorites_retry_button` | `features/core/catalog/module/lib/ui/views/favorites/favorites_error.dart` |
| Favoritos | Estado | `favorites_state_<loading|data|empty|error>` | `features/core/catalog/module/lib/ui/views/favorites/favorites_data.dart`<br>`features/core/catalog/module/lib/ui/views/favorites/favorites_empty.dart`<br>`features/core/catalog/module/lib/ui/views/favorites/favorites_error.dart`<br>`features/core/catalog/module/lib/ui/views/favorites/favorites_shimmer.dart` |
| Favoritos | Item | `favorites_item_<product id>` | `features/core/catalog/module/lib/ui/views/favorites/favorites_data.dart` |
| Favoritos | Producto · tarjeta | `favorites_product_card_<product id>` | `features/core/catalog/module/lib/ui/views/favorites/favorites_data.dart` |
| Favoritos | Alternar · botón | `favorites_toggle_button_<product id>` | `features/core/catalog/module/lib/ui/views/favorites/favorites_data.dart` |
| Favoritos | Mover a carrito · botón | `favorites_move_to_cart_button_<product id>` | `features/core/catalog/module/lib/ui/views/favorites/favorites_data.dart` |

## Reseña

Constantes: `ReviewFormSemanticIds` en `packages/features/core/catalog/constants/lib/catalog_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Reseña | Pantalla | `review_form_view` | `features/core/catalog/module/lib/ui/views/review_form/review_form_view.dart` |
| Reseña | Título · texto | `review_form_title_text` | `features/core/catalog/module/lib/ui/views/review_form/review_form_view.dart` |
| Reseña | Producto nombre · texto | `review_form_product_name_text` | `features/core/catalog/module/lib/ui/views/review_form/review_form_body.dart` |
| Reseña | Comentario · campo | `review_form_comment_input` | `features/core/catalog/module/lib/ui/views/review_form/review_form_body.dart` |
| Reseña | Error · texto | `review_form_error_text` | `features/core/catalog/module/lib/ui/views/review_form/review_form_body.dart` |
| Reseña | Enviar · botón | `review_form_submit_button` | `features/core/catalog/module/lib/ui/views/review_form/review_form_body.dart` |
| Reseña | Reintentar · botón | `review_form_retry_button` | `features/core/catalog/module/lib/ui/views/review_form/review_form_view.dart` |
| Reseña | Estado | `review_form_state_<loading|data|empty|error>` | `features/core/catalog/module/lib/ui/views/review_form/review_form_view.dart` |
| Reseña | Calificación · estrella | `review_form_rating_star_<1..5>` | `features/core/catalog/module/lib/ui/views/review_form/review_form_body.dart` |

## Carrito

Constantes: `CartSemanticIds` en `packages/features/core/cart/constants/lib/cart_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Carrito | Pantalla | `cart_view` | `features/core/cart/module/lib/ui/views/cart/cart_view.dart` |
| Carrito | Título · texto | `cart_title_text` | `features/core/cart/module/lib/ui/views/cart/cart_view.dart` |
| Carrito | Limpiar · botón | `cart_clear_button` | `features/core/cart/module/lib/ui/views/cart/cart_view.dart` |
| Carrito | Limpiar · diálogo | `cart_clear_dialog` | `features/core/cart/module/lib/ui/views/cart/cart_view.dart` |
| Carrito | Confirmar · diálogo limpiar | `cart_clear_dialog_confirm_button` | `features/core/cart/module/lib/ui/views/cart/cart_view.dart` |
| Carrito | Cancelar · diálogo limpiar | `cart_clear_dialog_cancel_button` | `features/core/cart/module/lib/ui/views/cart/cart_view.dart` |
| Carrito | Items · lista | `cart_items_list` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Item eliminado · texto | `cart_removed_item_text` | `features/core/cart/module/lib/ui/views/cart/cart_view.dart` |
| Carrito | Cupón · campo | `cart_coupon_input` | `features/core/cart/module/lib/ui/views/cart/cart_coupon.dart` |
| Carrito | Aplicar cupón · botón | `cart_apply_coupon_button` | `features/core/cart/module/lib/ui/views/cart/cart_coupon.dart` |
| Carrito | Cupón error · texto | `cart_coupon_error_text` | `features/core/cart/module/lib/ui/views/cart/cart_coupon.dart` |
| Carrito | Cupón aplicado · texto | `cart_coupon_applied_text` | `features/core/cart/module/lib/ui/views/cart/cart_coupon.dart` |
| Carrito | Quitar cupón · botón | `cart_remove_coupon_button` | `features/core/cart/module/lib/ui/views/cart/cart_coupon.dart` |
| Carrito | Subtotal · texto | `cart_subtotal_text` | `features/core/cart/module/lib/ui/views/cart/cart_totals.dart` |
| Carrito | Descuento · texto | `cart_discount_text` | `features/core/cart/module/lib/ui/views/cart/cart_totals.dart` |
| Carrito | Impuesto · texto | `cart_tax_text` | `features/core/cart/module/lib/ui/views/cart/cart_totals.dart` |
| Carrito | Total · texto | `cart_total_text` | `features/core/cart/module/lib/ui/views/cart/cart_totals.dart` |
| Carrito | Checkout · botón | `cart_checkout_button` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Vacío ir a catálogo · botón | `cart_empty_go_to_catalog_button` | `features/core/cart/module/lib/ui/views/cart/cart_empty.dart` |
| Carrito | Reintentar · botón | `cart_retry_button` | `features/core/cart/module/lib/ui/views/cart/cart_error.dart` |
| Carrito | Estado | `cart_state_<loading|data|empty|error>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart`<br>`features/core/cart/module/lib/ui/views/cart/cart_empty.dart`<br>`features/core/cart/module/lib/ui/views/cart/cart_error.dart`<br>`features/core/cart/module/lib/ui/views/cart/cart_shimmer.dart` |
| Carrito | Item | `cart_item_<line id>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Item cantidad · selector de cantidad | `cart_quantity_stepper_<line id>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Item cantidad · texto | `cart_quantity_text_<line id>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Restar cantidad · botón | `cart_decrease_quantity_button_<line id>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Sumar cantidad · botón | `cart_increase_quantity_button_<line id>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Item total · texto | `cart_line_total_text_<line id>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |
| Carrito | Quitar item · botón | `cart_remove_item_button_<line id>` | `features/core/cart/module/lib/ui/views/cart/cart_data.dart` |

## Checkout

Constantes: `CheckoutSemanticIds` en `packages/features/core/cart/constants/lib/cart_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Checkout | Pantalla | `checkout_view` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Título · texto | `checkout_title_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Paso · indicador | `checkout_step_indicator` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Reintentar · botón | `checkout_retry_button` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Dirección indicación · texto | `checkout_address_prompt_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_delivery.dart` |
| Checkout | Agregar dirección · botón | `checkout_add_address_button` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_delivery.dart` |
| Checkout | Dirección form · hoja inferior | `checkout_address_form_sheet` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_delivery.dart` |
| Checkout | Dirección etiqueta · campo | `checkout_address_label_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_address_form.dart` |
| Checkout | Dirección línea 1 · campo | `checkout_address_line1_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_address_form.dart` |
| Checkout | Dirección ciudad · campo | `checkout_address_city_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_address_form.dart` |
| Checkout | Dirección región · campo | `checkout_address_region_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_address_form.dart` |
| Checkout | Dirección notas · campo | `checkout_address_notes_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_address_form.dart` |
| Checkout | Dirección guardar · botón | `checkout_address_save_button` | `features/core/cart/module/lib/ui/views/checkout/checkout_address_form.dart` |
| Checkout | Tarjeta número · campo | `checkout_card_number_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_payment.dart` |
| Checkout | Tarjeta titular · campo | `checkout_card_holder_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_payment.dart` |
| Checkout | Tarjeta vencimiento · campo | `checkout_card_expiry_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_payment.dart` |
| Checkout | Tarjeta cvv · campo | `checkout_card_cvv_input` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_payment.dart` |
| Checkout | Error · texto | `checkout_error_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |
| Checkout | Resumen dirección · texto | `checkout_summary_address_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |
| Checkout | Resumen pago · texto | `checkout_summary_payment_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |
| Checkout | Subtotal · texto | `checkout_subtotal_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |
| Checkout | Descuento · texto | `checkout_discount_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |
| Checkout | Impuesto · texto | `checkout_tax_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |
| Checkout | Total · texto | `checkout_total_text` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |
| Checkout | Atrás · botón | `checkout_back_button` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Siguiente · botón | `checkout_next_button` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Confirmar · botón | `checkout_confirm_button` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Estado | `checkout_state_<loading|data|error>` | `features/core/cart/module/lib/ui/views/checkout/checkout_view.dart` |
| Checkout | Dirección · opción | `checkout_address_option_<address id>` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_delivery.dart` |
| Checkout | Pago · opción | `checkout_payment_method_<card|cash|transfer>` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_payment.dart` |
| Checkout | Resumen · item | `checkout_summary_item_<cart line id>` | `features/core/cart/module/lib/ui/views/checkout/checkout_step_summary.dart` |

## Compra confirmada

Constantes: `CheckoutSuccessSemanticIds` en `packages/features/core/cart/constants/lib/cart_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Compra confirmada | Pantalla | `checkout_success_view` | `features/core/cart/module/lib/ui/views/checkout_success/checkout_success_view.dart` |
| Compra confirmada | Titular · texto | `checkout_success_headline_text` | `features/core/cart/module/lib/ui/views/checkout_success/checkout_success_view.dart` |
| Compra confirmada | Pedido número · texto | `checkout_success_order_number_text` | `features/core/cart/module/lib/ui/views/checkout_success/checkout_success_view.dart` |
| Compra confirmada | Ir a pedido · botón | `checkout_success_go_to_order_button` | `features/core/cart/module/lib/ui/views/checkout_success/checkout_success_view.dart` |
| Compra confirmada | Ir a inicio · botón | `checkout_success_go_to_home_button` | `features/core/cart/module/lib/ui/views/checkout_success/checkout_success_view.dart` |

## Pedidos

Constantes: `OrdersListSemanticIds` en `packages/features/core/orders/constants/lib/orders_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Pedidos | Pantalla | `orders_list_view` | `features/core/orders/module/lib/ui/views/list/list_view.dart` |
| Pedidos | Título · texto | `orders_list_title_text` | `features/core/orders/module/lib/ui/views/list/list_view.dart` |
| Pedidos | Búsqueda · campo | `orders_search_input` | `features/core/orders/module/lib/ui/views/list/list_view.dart` |
| Pedidos | Estado · filtros | `orders_status_filters` | `features/core/orders/module/lib/ui/views/list/list_view.dart` |
| Pedidos | Reintentar · botón | `orders_retry_button` | `features/core/orders/module/lib/ui/views/list/list_error.dart` |
| Pedidos | Estado | `orders_state_<loading|data|empty|error>` | `features/core/orders/module/lib/ui/views/list/list_data.dart`<br>`features/core/orders/module/lib/ui/views/list/list_empty.dart`<br>`features/core/orders/module/lib/ui/views/list/list_error.dart`<br>`features/core/orders/module/lib/ui/views/list/list_shimmer.dart` |
| Pedidos | Estado · filtro | `orders_status_filter_<all|created|paid|shipped|delivered|cancelled>` | `features/core/orders/module/lib/ui/views/list/list_view.dart` |
| Pedidos | Item | `orders_item_<order id>` | `features/core/orders/module/lib/ui/views/list/list_data.dart` |

## Detalle de pedido

Constantes: `OrderDetailSemanticIds` en `packages/features/core/orders/constants/lib/orders_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Detalle de pedido | Pantalla | `order_detail_view` | `features/core/orders/module/lib/ui/views/detail/detail_view.dart` |
| Detalle de pedido | Título · texto | `order_detail_title_text` | `features/core/orders/module/lib/ui/views/detail/detail_view.dart` |
| Detalle de pedido | Pedido número · texto | `order_detail_order_number_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Fecha · texto | `order_detail_date_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Línea de tiempo | `order_detail_timeline` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Dirección · texto | `order_detail_address_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Pago · texto | `order_detail_payment_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Subtotal · texto | `order_detail_subtotal_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Descuento · texto | `order_detail_discount_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Impuesto · texto | `order_detail_tax_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Total · texto | `order_detail_total_text` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Cancelar · botón | `order_detail_cancel_button` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Cancelar · diálogo | `order_detail_cancel_dialog` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Confirmar · diálogo cancelar | `order_detail_cancel_dialog_confirm_button` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Mantener · diálogo cancelar | `order_detail_cancel_dialog_cancel_button` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Volver a pedir · botón | `order_detail_reorder_button` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |
| Detalle de pedido | Mensaje · texto | `order_detail_message_text` | `features/core/orders/module/lib/ui/views/detail/detail_view.dart` |
| Detalle de pedido | Reintentar · botón | `order_detail_retry_button` | `features/core/orders/module/lib/ui/views/detail/detail_error.dart` |
| Detalle de pedido | Estado | `order_detail_state_<loading|data|empty|error>` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart`<br>`features/core/orders/module/lib/ui/views/detail/detail_empty.dart`<br>`features/core/orders/module/lib/ui/views/detail/detail_error.dart`<br>`features/core/orders/module/lib/ui/views/detail/detail_shimmer.dart` |
| Detalle de pedido | Item | `order_detail_item_<order item id>` | `features/core/orders/module/lib/ui/views/detail/detail_data.dart` |

## Perfil

Constantes: `ProfileSemanticIds` en `packages/features/generic/profile/constants/lib/profile_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Perfil | Pantalla | `profile_view` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Título · texto | `profile_title_text` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Avatar · imagen | `profile_avatar_image` | `features/generic/profile/module/lib/ui/views/profile/profile_header.dart` |
| Perfil | Nombre · texto | `profile_name_text` | `features/generic/profile/module/lib/ui/views/profile/profile_header.dart` |
| Perfil | Correo · texto | `profile_email_text` | `features/generic/profile/module/lib/ui/views/profile/profile_header.dart` |
| Perfil | Teléfono · texto | `profile_phone_text` | `features/generic/profile/module/lib/ui/views/profile/profile_header.dart` |
| Perfil | Editar · botón | `profile_edit_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Nombre · campo | `profile_name_input` | `features/generic/profile/module/lib/ui/views/profile/profile_edit_form.dart` |
| Perfil | Teléfono · campo | `profile_phone_input` | `features/generic/profile/module/lib/ui/views/profile/profile_edit_form.dart` |
| Perfil | Avatar elegir · botón | `profile_avatar_picker_button` | `features/generic/profile/module/lib/ui/views/profile/profile_edit_form.dart` |
| Perfil | Cancelar editar · botón | `profile_cancel_edit_button` | `features/generic/profile/module/lib/ui/views/profile/profile_edit_form.dart` |
| Perfil | Guardar · botón | `profile_save_button` | `features/generic/profile/module/lib/ui/views/profile/profile_edit_form.dart` |
| Perfil | Change contraseña · botón | `profile_change_password_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Contraseña · hoja inferior | `profile_password_sheet` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Actual contraseña · campo | `profile_current_password_input` | `features/generic/profile/module/lib/ui/views/profile/profile_password_sheet.dart` |
| Perfil | Nueva contraseña · campo | `profile_new_password_input` | `features/generic/profile/module/lib/ui/views/profile/profile_password_sheet.dart` |
| Perfil | Confirmar nueva contraseña · campo | `profile_confirm_new_password_input` | `features/generic/profile/module/lib/ui/views/profile/profile_password_sheet.dart` |
| Perfil | Contraseña error · texto | `profile_password_error_text` | `features/generic/profile/module/lib/ui/views/profile/profile_password_sheet.dart` |
| Perfil | Enviar contraseña · botón | `profile_submit_password_button` | `features/generic/profile/module/lib/ui/views/profile/profile_password_sheet.dart` |
| Perfil | Ir a direcciones · botón | `profile_go_to_addresses_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Ir a ajustes · botón | `profile_go_to_settings_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Cerrar sesión · botón | `profile_logout_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Cerrar sesión · diálogo | `profile_logout_dialog` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Confirmar · diálogo cerrar sesión | `profile_logout_dialog_confirm_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Cancelar · diálogo cerrar sesión | `profile_logout_dialog_cancel_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Error · texto | `profile_error_text` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Eliminar cuenta · botón | `profile_delete_account_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Eliminar cuenta · diálogo | `profile_delete_account_dialog` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Confirmar · diálogo eliminar cuenta | `profile_delete_account_dialog_confirm_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Cancelar · diálogo eliminar cuenta | `profile_delete_account_dialog_cancel_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Eliminar cuenta segundo · diálogo | `profile_delete_account_second_dialog` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Confirmar · diálogo eliminar cuenta segundo | `profile_delete_account_second_dialog_confirm_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Cancelar · diálogo eliminar cuenta segundo | `profile_delete_account_second_dialog_cancel_button` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |
| Perfil | Mensaje · texto | `profile_message_text` | `features/generic/profile/module/lib/ui/views/profile/profile_view.dart` |

## Direcciones

Constantes: `AddressesSemanticIds` en `packages/features/generic/profile/constants/lib/profile_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Direcciones | Pantalla | `addresses_view` | `features/generic/profile/module/lib/ui/views/addresses/addresses_view.dart` |
| Direcciones | Título · texto | `addresses_title_text` | `features/generic/profile/module/lib/ui/views/addresses/addresses_view.dart` |
| Direcciones | Agregar · botón | `addresses_add_button` | `features/generic/profile/module/lib/ui/views/addresses/addresses_view.dart` |
| Direcciones | Error · texto | `addresses_error_text` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |
| Direcciones | Form · hoja inferior | `addresses_form_sheet` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart`<br>`features/generic/profile/module/lib/ui/views/addresses/addresses_view.dart` |
| Direcciones | Etiqueta · campo | `addresses_label_input` | `features/generic/profile/module/lib/ui/views/addresses/addresses_form_sheet.dart` |
| Direcciones | Línea 1 · campo | `addresses_line1_input` | `features/generic/profile/module/lib/ui/views/addresses/addresses_form_sheet.dart` |
| Direcciones | Ciudad · campo | `addresses_city_input` | `features/generic/profile/module/lib/ui/views/addresses/addresses_form_sheet.dart` |
| Direcciones | Región · campo | `addresses_region_input` | `features/generic/profile/module/lib/ui/views/addresses/addresses_form_sheet.dart` |
| Direcciones | Notas · campo | `addresses_notes_input` | `features/generic/profile/module/lib/ui/views/addresses/addresses_form_sheet.dart` |
| Direcciones | Guardar · botón | `addresses_save_button` | `features/generic/profile/module/lib/ui/views/addresses/addresses_form_sheet.dart` |
| Direcciones | Eliminar · diálogo | `addresses_delete_dialog` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |
| Direcciones | Confirmar · diálogo eliminar | `addresses_delete_dialog_confirm_button` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |
| Direcciones | Cancelar · diálogo eliminar | `addresses_delete_dialog_cancel_button` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |
| Direcciones | Reintentar · botón | `addresses_retry_button` | `features/generic/profile/module/lib/ui/views/addresses/addresses_error.dart` |
| Direcciones | Estado | `addresses_state_<loading|data|empty|error>` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart`<br>`features/generic/profile/module/lib/ui/views/addresses/addresses_empty.dart`<br>`features/generic/profile/module/lib/ui/views/addresses/addresses_error.dart`<br>`features/generic/profile/module/lib/ui/views/addresses/addresses_shimmer.dart` |
| Direcciones | Item | `addresses_item_<address id>` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |
| Direcciones | Marcar predeterminada · botón | `addresses_set_default_button_<address id>` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |
| Direcciones | Editar · botón | `addresses_edit_button_<address id>` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |
| Direcciones | Eliminar · botón | `addresses_delete_button_<address id>` | `features/generic/profile/module/lib/ui/views/addresses/addresses_data.dart` |

## Ajustes

Constantes: `SettingsSemanticIds` en `packages/features/generic/app_cross/constants/lib/app_cross_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Ajustes | Pantalla | `settings_view` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Título · texto | `settings_title_text` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Idioma · selector | `settings_language_selector` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Tema · selector | `settings_theme_selector` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Moneda · selector | `settings_currency_selector` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Error · texto | `settings_error_text` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Ver onboarding de nuevo · botón | `settings_see_onboarding_again_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Restablecer demo datos · botón | `settings_reset_demo_data_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Restablecer demo datos · diálogo | `settings_reset_demo_data_dialog` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Confirmar · diálogo restablecer demo datos | `settings_reset_demo_data_dialog_confirm_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Cancelar · diálogo restablecer demo datos | `settings_reset_demo_data_dialog_cancel_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Borrar datos · botón | `settings_wipe_data_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Borrar datos · diálogo | `settings_wipe_data_dialog` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Confirmar · diálogo borrar datos | `settings_wipe_data_dialog_confirm_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Cancelar · diálogo borrar datos | `settings_wipe_data_dialog_cancel_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Ir a acerca de · botón | `settings_go_to_about_button` | `features/generic/app_cross/module/lib/ui/views/settings/settings_actions_section.dart` |
| Ajustes | Idioma · opción | `settings_language_option_<es|en>` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Tema · opción | `settings_theme_option_<system|light|dark>` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |
| Ajustes | Moneda · opción | `settings_currency_option_<code>` | `features/generic/app_cross/module/lib/ui/views/settings/settings_view.dart` |

## Acerca de

Constantes: `AboutSemanticIds` en `packages/features/generic/app_cross/constants/lib/app_cross_semantic_ids.dart`.

| Pantalla | Elemento | Identifier | Archivo |
|---|---|---|---|
| Acerca de | Pantalla | `about_view` | `features/generic/app_cross/module/lib/ui/views/about/about_view.dart` |
| Acerca de | Título · texto | `about_title_text` | `features/generic/app_cross/module/lib/ui/views/about/about_view.dart` |
| Acerca de | Versión · texto | `about_version_text` | `features/generic/app_cross/module/lib/ui/views/about/about_view.dart` |
| Acerca de | Plataforma · texto | `about_platform_text` | `features/generic/app_cross/module/lib/ui/views/about/about_view.dart` |
