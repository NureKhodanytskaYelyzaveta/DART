import 'dart:async';

import 'package:fleet_service/fleet_service.dart';
import 'package:test/test.dart';

/// Невелика затримка для тестів, де важливий проміжний стан.
const Duration _smallLatency = Duration(milliseconds: 20);

ServiceRecord _record(String plate) => ServiceRecord(
  plate: plate,
  workType: WorkType.oilChange,
  mileage: 10000,
  date: DateTime(2026, 3, 1),
  cost: 1500,
  performer: 'СТО «Мотор»',
);

void main() {
  group('AsyncRepository', () {
    var repository = AsyncRepository<ServiceRecord>(latency: Duration.zero);

    setUp(() {
      repository = AsyncRepository<ServiceRecord>(latency: Duration.zero);
    });

    test('save зберігає запис, load повертає його', () async {
      final record = _record('AX1111AX');
      await repository.save(record);
      await expectLater(repository.load(record.id), completion(equals(record)));
    });

    test('load повертає null для невідомого ідентифікатора', () async {
      await expectLater(repository.load('немає'), completion(isNull));
    });

    test('delete видаляє запис і повідомляє, чи він існував', () async {
      final record = _record('AX2222AX');
      await repository.save(record);
      await expectLater(repository.delete(record.id), completion(isTrue));
      await expectLater(repository.delete(record.id), completion(isFalse));
      expect(repository.length, 0);
    });

    test('loadOrThrow кидає EntityNotFoundException', () async {
      await expectLater(
        repository.loadOrThrow('немає'),
        throwsA(isA<EntityNotFoundException>()),
      );
    });

    test(
      'забутий await: запис з’являється лише після завершення save',
      () async {
        final slow = AsyncRepository<ServiceRecord>(latency: _smallLatency);
        final pending = slow.save(_record('AX3333AX'));
        expect(slow.length, 0);
        await pending;
        expect(slow.length, 1);
      },
    );

    test('.wait повідомляє, яка саме операція завершилась помилкою', () async {
      final record = _record('AX4444AX');
      await repository.save(record);
      final operations = [
        repository.load(record.id),
        repository.loadOrThrow('немає'),
      ];
      try {
        await operations.wait;
        fail('Очікувалась ParallelWaitError');
      } on ParallelWaitError<List<ServiceRecord?>, List<AsyncError?>> catch (
        error
      ) {
        expect(error.values[0], record);
        expect(error.values[1], isNull);
        expect(error.errors[0], isNull);
        expect(error.errors[1]?.error, isA<EntityNotFoundException>());
      }
    });

    test('watchAll видає записи в порядку додавання', () async {
      final plates = ['AX0001AX', 'AX0002AX', 'AX0003AX'];
      final ordered = AsyncRepository<ServiceRecord>(
        streamInterval: Duration.zero,
        initial: plates.map(_record),
      );
      await expectLater(
        ordered.watchAll().map((record) => record.plate),
        emitsInOrder([...plates, emitsDone]),
      );
    });

    test('сховище приймає записи, розібрані з рядків ЛР 2', () async {
      final records = loadDemoRecords();
      final loaded = AsyncRepository<ServiceRecord>(
        latency: Duration.zero,
        initial: records,
      );
      await expectLater(
        loaded.load(records.first.id),
        completion(equals(records.first)),
      );
    });
  });

  group('AsyncRepository і шина подій', () {
    test('save і delete публікують added, updated, removed по черзі', () async {
      final bus = ChangeEventBus<ServiceRecord>();
      final repository = AsyncRepository<ServiceRecord>(
        latency: Duration.zero,
        changes: bus,
      );
      final record = _record('AX5555AX');

      await repository.save(record);
      await repository.save(record);
      await repository.delete(record.id);
      final closing = bus.close();

      await expectLater(
        bus.events.map((event) => event.type),
        emitsInOrder([
          ChangeType.added,
          ChangeType.updated,
          ChangeType.removed,
          emitsDone,
        ]),
      );
      await closing;
    });
  });
}
