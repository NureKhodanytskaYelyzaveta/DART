import 'dart:async';

import 'package:fleet_service/fleet_service.dart';
import 'package:test/test.dart';

ChangeEvent<ServiceRecord> _event(ChangeType type, ServiceRecord record) =>
    ChangeEvent(type, record);

void main() {
  group('ChangeEventBus', () {
    final records = loadDemoRecords();
    var bus = ChangeEventBus<ServiceRecord>();

    setUp(() {
      bus = ChangeEventBus<ServiceRecord>();
    });

    test(
      'події, додані до підписки, не губляться і зберігають порядок',
      () async {
        final first = _event(ChangeType.added, records[0]);
        final second = _event(ChangeType.updated, records[1]);
        final third = _event(ChangeType.removed, records[2]);
        bus
          ..publish(first)
          ..publish(second)
          ..publish(third);
        final closing = bus.close();

        await expectLater(
          bus.events,
          emitsInOrder([first, second, third, emitsDone]),
        );
        await closing;
      },
    );

    test('помилка в середині потоку не змінює порядок решти подій', () async {
      final before = _event(ChangeType.added, records[0]);
      final after = _event(ChangeType.added, records[1]);
      bus
        ..publish(before)
        ..publishError(StateError('збій'))
        ..publish(after);
      final closing = bus.close();

      await expectLater(
        bus.events,
        emitsInOrder([before, emitsError(isA<StateError>()), after, emitsDone]),
      );
      await closing;
    });

    test('одноразовий потік не дозволяє другу підписку', () async {
      final subscription = bus.events.listen((_) {});
      expect(() => bus.events.listen((_) {}), throwsStateError);
      await subscription.cancel();
      await bus.close();
    });

    test('широкомовний потік доставляє подію кожному підписнику', () async {
      final broadcast = ChangeEventBus<ServiceRecord>(broadcast: true);
      final received = <String>[];
      final a = broadcast.events.listen((event) => received.add('a'));
      final b = broadcast.events.listen((event) => received.add('b'));

      broadcast.publish(_event(ChangeType.added, records[0]));
      await Future<void>.delayed(Duration.zero);

      expect(received, unorderedEquals(['a', 'b']));
      await a.cancel();
      await b.cancel();
      await broadcast.close();
    });

    test('після cancel підписник більше не отримує подій', () async {
      final broadcast = ChangeEventBus<ServiceRecord>(broadcast: true);
      var delivered = 0;
      final subscription = broadcast.events.listen((_) => delivered++);

      broadcast.publish(_event(ChangeType.added, records[0]));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      broadcast.publish(_event(ChangeType.added, records[1]));
      await Future<void>.delayed(Duration.zero);

      expect(delivered, 1);
      await broadcast.close();
    });

    test(
      'конвеєр where → map → take залишає перші два додані записи',
      () async {
        bus
          ..publish(_event(ChangeType.added, records[0]))
          ..publish(_event(ChangeType.updated, records[1]))
          ..publish(_event(ChangeType.added, records[2]))
          ..publish(_event(ChangeType.added, records[3]));
        final closing = bus.close();

        await expectLater(
          buildAddedIdsPipeline(bus.events),
          emitsInOrder([records[0].id, records[2].id, emitsDone]),
        );
        await closing;
      },
    );
  });
}
