import 'dart:isolate';

import 'package:fleet_service/fleet_service.dart';
import 'package:test/test.dart';

/// Розмір вибірки, достатній для перевірки й швидкий для тестів.
const int _smallCount = 20000;

void main() {
  group('Ізоляти', () {
    test(
      'Isolate.run повертає той самий результат, що й головний ізолят',
      () async {
        final expected = aggregateCostByPlate(_smallCount);
        final actual = await Isolate.run(
          () => aggregateCostByPlate(_smallCount),
        );
        expect(actual, expected);
        expect(actual, isNotEmpty);
      },
    );

    test('зміна глобальної змінної в ізоляті не видна в головному', () async {
      final result = await demonstrateGlobalIsolation();
      expect(result.insideIsolate, greaterThan(0));
      expect(result.inMain, 0);
    });
  });
}
