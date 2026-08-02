import 'package:sqflite/sqflite.dart';
import 'package:utilities/utilities.dart';

/// Deterministic demo seed.
///
/// Every id, price and date is a fixed literal: no `Random`, no
/// `DateTime.now()`. Running the app twice with `SEED_MODE=demo` always
/// produces exactly the same content.
///
/// Demo credentials (documented in the README):
///  * `ana@market.demo` / `Demo1234`
///  * `bruno@market.demo` / `Demo1234`
class Seed {
  const Seed._();

  /// Demo password shared by the two seeded users.
  static const String demoPassword = 'Demo1234';

  static const String userAna = 'user_demo_001';
  static const String userBruno = 'user_demo_002';

  /// Applies the whole seed inside the given executor (a transaction).
  static Future<void> apply(DatabaseExecutor txn) async {
    final Batch batch = txn.batch();
    _users(batch);
    _categories(batch);
    _products(batch);
    _coupons(batch);
    _addresses(batch);
    _historicalOrder(batch);
    _reviews(batch);
    _notifications(batch);
    await batch.commit(noResult: true);
  }

  static int _utc(int year, int month, int day) =>
      DateTime.utc(year, month, day, 12).millisecondsSinceEpoch;

  static void _users(Batch batch) {
    batch
      ..insert('users', <String, Object?>{
        'id': userAna,
        'full_name': 'Ana Marín',
        'email': 'ana@market.demo',
        'phone': '+57 300 111 2233',
        'avatar_path': null,
        'password_hash': PasswordHasher.hash(
          password: demoPassword,
          salt: 'salt_user_demo_001',
        ),
        'password_salt': 'salt_user_demo_001',
        'created_at': _utc(2026, 1, 10),
      })
      ..insert('users', <String, Object?>{
        'id': userBruno,
        'full_name': 'Bruno Vega',
        'email': 'bruno@market.demo',
        'phone': '+57 300 444 5566',
        'avatar_path': null,
        'password_hash': PasswordHasher.hash(
          password: demoPassword,
          salt: 'salt_user_demo_002',
        ),
        'password_salt': 'salt_user_demo_002',
        'created_at': _utc(2026, 1, 11),
      });
  }

  static void _categories(Batch batch) {
    const List<List<String>> rows = <List<String>>[
      <String>['cat_car', 'CAR', 'Cars'],
      <String>['cat_motorcycle', 'MOTORCYCLE', 'Motorcycles'],
      <String>['cat_scooter', 'SCOOTER', 'Scooters'],
      <String>['cat_bicycle', 'BICYCLE', 'Bicycles'],
      <String>['cat_truck', 'TRUCK', 'Trucks'],
    ];
    for (final List<String> row in rows) {
      batch.insert('categories', <String, Object?>{
        'id': row[0],
        'code': row[1],
        'name': row[2],
      });
    }
  }

  static void _products(Batch batch) {
    // id, name, description, price, stock, category, condition, owner, day
    final List<List<Object?>> rows = <List<Object?>>[
      <Object?>[
        'product_car_001',
        'Sedán compacto 2022',
        'Sedán compacto en excelente estado, único dueño, mantenimiento al día.',
        45000000.0,
        1,
        'cat_car',
        'USED',
        userAna,
        12,
      ],
      <Object?>[
        'product_car_002',
        'SUV familiar 2024',
        'SUV de 7 puestos, cero kilómetros, garantía de fábrica vigente.',
        62500000.0,
        2,
        'cat_car',
        'NEW',
        userBruno,
        13,
      ],
      <Object?>[
        'product_car_003',
        'Hatchback urbano 2021',
        'Hatchback ideal para ciudad, bajo consumo y fácil de parquear.',
        38900000.0,
        1,
        'cat_car',
        'USED',
        userBruno,
        14,
      ],
      <Object?>[
        'product_moto_001',
        'Moto urbana 160cc',
        'Moto urbana 160cc con frenos ABS y consumo muy bajo, papeles al día.',
        8500000.0,
        3,
        'cat_motorcycle',
        'NEW',
        userAna,
        15,
      ],
      <Object?>[
        'product_moto_002',
        'Moto doble propósito 250cc',
        'Doble propósito 250cc lista para carretera y trocha, llantas nuevas.',
        12300000.0,
        2,
        'cat_motorcycle',
        'USED',
        userBruno,
        16,
      ],
      <Object?>[
        'product_moto_003',
        'Scooter automática 125cc',
        'Scooter automática 125cc, perfecta para el día a día en la ciudad.',
        6700000.0,
        4,
        'cat_motorcycle',
        'NEW',
        userBruno,
        17,
      ],
      <Object?>[
        'product_scooter_001',
        'Patineta eléctrica plegable',
        'Patineta eléctrica plegable con 30 km de autonomía y luces LED.',
        1450000.0,
        5,
        'cat_scooter',
        'NEW',
        userAna,
        18,
      ],
      <Object?>[
        'product_scooter_002',
        'Patineta eléctrica todoterreno',
        'Patineta todoterreno con suspensión doble y llantas de 10 pulgadas.',
        2100000.0,
        2,
        'cat_scooter',
        'NEW',
        userBruno,
        19,
      ],
      <Object?>[
        'product_scooter_003',
        'Patineta eléctrica básica',
        'Patineta básica usada, batería reciente, ideal primer vehículo.',
        990000.0,
        0,
        'cat_scooter',
        'USED',
        userBruno,
        20,
      ],
      <Object?>[
        'product_bike_001',
        'Bicicleta de montaña 29"',
        'Bicicleta de montaña rin 29 con suspensión bloqueable y 21 cambios.',
        1800000.0,
        3,
        'cat_bicycle',
        'NEW',
        userAna,
        21,
      ],
      <Object?>[
        'product_bike_002',
        'Bicicleta de ruta carbono',
        'Bicicleta de ruta con marco de carbono, grupo completo, talla M.',
        3200000.0,
        1,
        'cat_bicycle',
        'USED',
        userBruno,
        22,
      ],
      <Object?>[
        'product_bike_003',
        'Bicicleta urbana con canasta',
        'Bicicleta urbana cómoda con canasta, guardabarros y luces incluidas.',
        950000.0,
        6,
        'cat_bicycle',
        'USED',
        userBruno,
        23,
      ],
      <Object?>[
        'product_truck_001',
        'Camioneta 4x4 diésel',
        'Camioneta 4x4 diésel con platón, perfecta para carga y finca.',
        95000000.0,
        1,
        'cat_truck',
        'USED',
        userAna,
        24,
      ],
      <Object?>[
        'product_truck_002',
        'Camioneta doble cabina 2025',
        'Doble cabina 2025 cero kilómetros, full equipo, garantía extendida.',
        120000000.0,
        2,
        'cat_truck',
        'NEW',
        userBruno,
        25,
      ],
      <Object?>[
        'product_truck_003',
        'Camioneta de reparto',
        'Camioneta de reparto con furgón cerrado, lista para trabajar.',
        78500000.0,
        1,
        'cat_truck',
        'USED',
        userBruno,
        26,
      ],
    ];
    for (final List<Object?> row in rows) {
      final int createdAt = _utc(2026, 1, row[8]! as int);
      batch.insert('products', <String, Object?>{
        'id': row[0],
        'name': row[1],
        'description': row[2],
        'price': row[3],
        'stock': row[4],
        'category_id': row[5],
        'image_path': null,
        'condition': row[6],
        'status': 'ACTIVE',
        'owner_id': row[7],
        'created_at': createdAt,
        'updated_at': createdAt,
      });
    }
  }

  static void _coupons(Batch batch) {
    batch
      ..insert('coupons', <String, Object?>{
        'code': 'DEMO10',
        'discount_pct': 10.0,
        'min_amount': 2000000.0,
        'valid_until': _utc(2030, 1, 1),
        'is_active': 1,
      })
      ..insert('coupons', <String, Object?>{
        'code': 'PAST20',
        'discount_pct': 20.0,
        'min_amount': 0.0,
        'valid_until': _utc(2024, 1, 1),
        'is_active': 1,
      })
      ..insert('coupons', <String, Object?>{
        'code': 'FROZEN15',
        'discount_pct': 15.0,
        'min_amount': 0.0,
        'valid_until': _utc(2030, 1, 1),
        'is_active': 0,
      });
  }

  static void _addresses(Batch batch) {
    batch
      ..insert('addresses', <String, Object?>{
        'id': 'addr_demo_home',
        'user_id': userAna,
        'label': 'Casa',
        'line1': 'Calle 45 # 12-34, Apto 501',
        'city': 'Bogotá',
        'state': 'Cundinamarca',
        'notes': 'Torre B, timbre 501',
        'is_default': 1,
      })
      ..insert('addresses', <String, Object?>{
        'id': 'addr_demo_office',
        'user_id': userAna,
        'label': 'Oficina',
        'line1': 'Carrera 7 # 71-21, Piso 8',
        'city': 'Bogotá',
        'state': 'Cundinamarca',
        'notes': null,
        'is_default': 0,
      });
  }

  static void _historicalOrder(Batch batch) {
    const double subtotal = 12300000.0 + 3200000.0;
    const double discount = 0.0;
    const double tax = (subtotal - discount) * 0.19;
    batch
      ..insert('orders', <String, Object?>{
        'id': 'order_demo_001',
        'user_id': userAna,
        'address_id': 'addr_demo_home',
        'coupon_code': null,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': subtotal - discount + tax,
        'payment_method': 'CARD',
        'status': 'DELIVERED',
        'created_at': _utc(2026, 2, 10),
      })
      ..insert('order_items', <String, Object?>{
        'id': 'order_item_demo_001',
        'order_id': 'order_demo_001',
        'product_id': 'product_moto_002',
        'name': 'Moto doble propósito 250cc',
        'unit_price': 12300000.0,
        'quantity': 1,
      })
      ..insert('order_items', <String, Object?>{
        'id': 'order_item_demo_002',
        'order_id': 'order_demo_001',
        'product_id': 'product_bike_002',
        'name': 'Bicicleta de ruta carbono',
        'unit_price': 3200000.0,
        'quantity': 1,
      });
  }

  static void _reviews(Batch batch) {
    batch.insert('reviews', <String, Object?>{
      'id': 'review_demo_001',
      'product_id': 'product_moto_002',
      'user_id': userAna,
      'rating': 5,
      'comment': 'Excelente moto, llegó impecable y tal como se describía.',
      'created_at': _utc(2026, 2, 15),
    });
  }

  static void _notifications(Batch batch) {
    batch.insert('notifications', <String, Object?>{
      'id': 'notification_demo_001',
      'user_id': userAna,
      'type': 'WELCOME',
      'title_key': 'app_cross.notifications.welcome_title',
      'body_key': 'app_cross.notifications.welcome_body',
      'payload': '{"route":"/dashboard"}',
      'is_read': 0,
      'created_at': _utc(2026, 1, 10),
    });
  }
}
