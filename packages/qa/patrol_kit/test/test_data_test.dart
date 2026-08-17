import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_kit/patrol_kit.dart';

/// What the JSON loader guarantees.
///
/// The point of every case here is the *shape of the failure*. A test data
/// layer that throws a `_TypeError` from somewhere inside `jsonDecode` is
/// worse than no layer at all: the run goes red, the message names a cast,
/// and whoever reads it starts by suspecting the product. Every read that
/// cannot be satisfied has to say which field, in which record, in which
/// file — and it has to throw a [TestDataError], because that is what makes
/// the step report as **broken** instead of **failed**.
void main() {
  const String index = '''
{
  "version": 1,
  "datasets": { "users": "users.json", "rows": "rows.json" }
}
''';

  const String users = '''
{
  "demo": {
    "email": "ana@market.demo",
    "publications": 5,
    "price": 62500000,
    "active": true,
    "roles": ["seller", "buyer"],
    "address": { "city": "Medellín" },
    "orders": [ { "id": "o1" }, { "id": "o2" } ]
  }
}
''';

  const String rows = '[ {"case": "uno"}, {"case": "dos"} ]';

  TestDataSource sourceWith([Map<String, String>? overrides]) =>
      InMemoryTestDataSource(<String, String>{
        'index.json': index,
        'users.json': users,
        'rows.json': rows,
        ...?overrides,
      });

  setUp(TestDataStore.reset);
  tearDown(TestDataStore.reset);

  group('the index is what says which files exist', () {
    test('every file it lists is loaded', () async {
      await TestDataStore.load(source: sourceWith());

      expect(TestDataStore.isLoaded, isTrue);
      expect(TestDataStore.dataset('users').keys, <String>['demo']);
      expect(TestDataStore.dataset('rows').length, 2);
    });

    test(
      'reading before loading names the cause that actually happens',
      () async {
        // Y la nombra bien. La primera versión de este mensaje decía "llama a
        // TestDataStore.load() en el launcher" — y cuando el fallo llegó de
        // verdad, el launcher SÍ lo llamaba: lo que pasaba es que un
        // testParam() en la cabecera del test leía los datos antes. El
        // mensaje mandó a mirar al sitio equivocado, así que ahora nombra el
        // orden, no la llamada.
        expect(
          () => TestDataStore.dataset('users'),
          throwsA(
            isA<TestDataError>().having(
              (TestDataError e) => e.message,
              'message',
              allOf(contains('ANTES'), contains('testParam')),
            ),
          ),
        );
      },
    );

    test(
      'a dataset the index never registered names the ones it did',
      () async {
        await TestDataStore.load(source: sourceWith());

        expect(
          () => TestDataStore.dataset('coupons'),
          throwsA(
            isA<TestDataError>().having(
              (TestDataError e) => e.message,
              'message',
              allOf(contains('coupons'), contains('users')),
            ),
          ),
        );
      },
    );

    test(
      'an empty index fails the run rather than leaving it dataless',
      () async {
        expect(
          () => TestDataStore.load(
            source: const InMemoryTestDataSource(<String, String>{
              'index.json': '{"datasets": {}}',
            }),
          ),
          throwsA(isA<TestDataError>()),
        );
      },
    );

    test(
      'a file the index points at but nobody wrote names the path',
      () async {
        expect(
          () => TestDataStore.load(
            source: const InMemoryTestDataSource(<String, String>{
              'index.json': '{"datasets": {"users": "missing.json"}}',
            }),
          ),
          throwsA(
            isA<TestDataError>().having(
              (TestDataError e) => e.message,
              'message',
              contains('missing.json'),
            ),
          ),
        );
      },
    );

    test('malformed JSON fails at load, naming the file', () async {
      expect(
        () => TestDataStore.load(
          source: sourceWith(<String, String>{'users.json': '{ not json'}),
        ),
        throwsA(
          isA<TestDataError>().having(
            (TestDataError e) => e.message,
            'message',
            allOf(contains('users.json'), contains('JSON')),
          ),
        ),
      );
    });
  });

  group('both file shapes are data', () {
    test('an object gives records by name, and still iterates', () async {
      await TestDataStore.load(source: sourceWith());
      final DataSet set = TestDataStore.dataset('users');

      expect(set.record('demo').string('email'), 'ana@market.demo');
      expect(set.rows, hasLength(1));
    });

    test('an array gives rows by position', () async {
      await TestDataStore.load(source: sourceWith());
      final DataSet set = TestDataStore.dataset('rows');

      expect(set.row(0).string('case'), 'uno');
      expect(set.rows.map((DataRecord r) => r.string('case')), <String>[
        'uno',
        'dos',
      ]);
    });

    test('asking an array for a named record says to use rows', () async {
      await TestDataStore.load(source: sourceWith());

      expect(
        () => TestDataStore.dataset('rows').record('uno'),
        throwsA(
          isA<TestDataError>().having(
            (TestDataError e) => e.message,
            'message',
            contains('.rows'),
          ),
        ),
      );
    });

    test('a row past the end says how many there are', () async {
      await TestDataStore.load(source: sourceWith());

      expect(
        () => TestDataStore.dataset('rows').row(7),
        throwsA(
          isA<TestDataError>().having(
            (TestDataError e) => e.message,
            'message',
            contains('tiene 2'),
          ),
        ),
      );
    });
  });

  group('a read either returns the value or explains itself', () {
    late DataRecord demo;

    setUp(() async {
      await TestDataStore.load(source: sourceWith());
      demo = TestDataStore.dataset('users').record('demo');
    });

    test('the typed accessors read what is there', () {
      expect(demo.string('email'), 'ana@market.demo');
      expect(demo.integer('publications'), 5);
      expect(demo.number('price'), 62500000.0);
      expect(demo.boolean('active'), isTrue);
      expect(demo.strings('roles'), <String>['seller', 'buyer']);
      expect(demo.child('address').string('city'), 'Medellín');
      expect(
        demo.children('orders').map((DataRecord o) => o.string('id')),
        <String>['o1', 'o2'],
      );
    });

    test('a whole number written as 5.0 still reads as an int', () async {
      await TestDataStore.load(
        source: sourceWith(<String, String>{
          'users.json': '{"demo": {"publications": 5.0}}',
        }),
      );

      expect(
        TestDataStore.dataset('users').record('demo').integer('publications'),
        5,
      );
    });

    test('a missing field names the field and lists what is there', () {
      expect(
        () => demo.string('telefono'),
        throwsA(
          isA<TestDataError>().having(
            (TestDataError e) => e.message,
            'message',
            allOf(
              contains('telefono'),
              contains('users.demo'),
              contains('email'),
            ),
          ),
        ),
      );
    });

    test('the wrong type names what it expected and what it found', () {
      expect(
        () => demo.integer('email'),
        throwsA(
          isA<TestDataError>().having(
            (TestDataError e) => e.message,
            'message',
            allOf(contains('users.demo.email'), contains('entero')),
          ),
        ),
      );
    });

    test('every failure is a TestDataError, so the step reports broken', () {
      // The whole reason the accessors exist. `stepOutcomeOf` reads a
      // `TestFailure` as the product being wrong and anything else as the
      // test being unable to check; data that cannot be read is the second.
      for (final void Function() read in <void Function()>[
        () => demo.string('nope'),
        () => demo.integer('email'),
        () => demo.child('email'),
        () => demo.children('email'),
        () => demo.strings('address'),
      ]) {
        Object? thrown;
        try {
          read();
        } on Object catch (error) {
          thrown = error;
        }
        expect(thrown, isA<TestDataError>());
        expect(stepOutcomeOf(thrown!), 'broken');
      }
    });

    test('has() and raw() are the escape hatch, and do not throw', () {
      expect(demo.has('email'), isTrue);
      expect(demo.has('telefono'), isFalse);
      expect(demo.raw('telefono'), isNull);
      expect(demo.fields, contains('roles'));
    });
  });
}
