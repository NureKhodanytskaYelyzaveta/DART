import 'dart:async';

import '../service_record.dart';
import 'async_repository.dart';
import 'change_event.dart';
import 'change_event_bus.dart';
import 'console.dart';
import 'demo_data.dart';

/// Коротка пауза, під час якої потік устигає доставити події.
const Duration _pause = Duration(milliseconds: 150);

/// Скільки доданих записів залишає конвеєр [buildAddedIdsPipeline].
const int _pipelineLimit = 2;

/// Крок 7. Споживає потік сховища циклом `await for`.
Future<void> consumeWithAwaitFor(
  AsyncRepository<ServiceRecord> repository,
) async {
  await for (final record in repository.watchAll()) {
    say('  await for отримав: ${record.id}');
  }
}

/// Потік-обгортка з повідомленням на початку тіла генератора.
Stream<ServiceRecord> _noisyWatch(
  AsyncRepository<ServiceRecord> repository,
) async* {
  say('  [генератор] тіло почало виконуватися');
  yield* repository.watchAll();
}

/// Крок 8. Доводить лінивість `async*`: тіло не виконується до підписки.
Future<void> demonstrateLazyGenerator(
  AsyncRepository<ServiceRecord> repository,
) async {
  final stream = _noisyWatch(repository);
  say('Потік створено, підписки немає');
  await Future<void>.delayed(_pause);
  say('Пауза минула, а повідомлення генератора досі немає');
  // first підписується, бере один елемент і скасовує підписку.
  final first = await stream.first;
  say('Після підписки отримано перший елемент: ${first.id}');
}

/// Публікує по одній події кожного виду для перших трьох записів.
void _publishThreeEvents(
  ChangeEventBus<ServiceRecord> bus,
  List<ServiceRecord> records,
) {
  bus
    ..publish(ChangeEvent(ChangeType.added, records[0]))
    ..publish(ChangeEvent(ChangeType.updated, records[1]))
    ..publish(ChangeEvent(ChangeType.removed, records[2]));
}

/// Кроки 9–10. Три події до підписки не губляться; підписку скасовано явно.
Future<void> demonstrateBufferedEvents() async {
  final bus = ChangeEventBus<ServiceRecord>();
  _publishThreeEvents(bus, loadDemoRecords());
  say('Три події опубліковано до підписки');

  final received = <ChangeEvent<ServiceRecord>>[];
  final subscription = bus.events.listen(received.add);
  try {
    await Future<void>.delayed(_pause);
    say('Після підписки доставлено ${received.length} події:');
    for (final event in received) {
      say('  $event');
    }
  } finally {
    await subscription.cancel();
    await bus.close();
  }
}

/// Публікує подію, помилку, ще одну подію й закриває шину.
Future<void> _publishWithError(
  ChangeEventBus<ServiceRecord> bus,
  List<ServiceRecord> records,
) async {
  bus
    ..publish(ChangeEvent(ChangeType.added, records[0]))
    ..publishError(StateError('Збій джерела подій'))
    ..publish(ChangeEvent(ChangeType.added, records[1]));
  await bus.close();
}

/// Крок 11. Помилка в середині потоку: `await for` проти `listen`.
Future<void> compareErrorHandling() async {
  final records = loadDemoRecords();

  say('await for:');
  final busA = ChangeEventBus<ServiceRecord>();
  final closingA = _publishWithError(busA, records);
  try {
    await for (final event in busA.events) {
      say('  подія: $event');
    }
  } on StateError catch (error) {
    say('  цикл перервано помилкою: ${error.message}');
  }
  await closingA;

  say('listen з cancelOnError: false:');
  final busB = ChangeEventBus<ServiceRecord>();
  final closingB = _publishWithError(busB, records);
  final finished = Completer<void>();
  final subscription = busB.events.listen(
    (event) => say('  подія: $event'),
    onError: (Object error) => say('  помилка: $error, підписка триває'),
    onDone: () {
      say('  потік завершено');
      finished.complete();
    },
    cancelOnError: false,
  );
  try {
    await finished.future;
  } finally {
    await subscription.cancel();
  }
  await closingB;
}

/// Крок 12. Одноразовий потік проти широкомовного: друга підписка.
Future<void> compareSingleAndBroadcast() async {
  final single = ChangeEventBus<ServiceRecord>();
  final first = single.events.listen((_) {});
  try {
    final second = single.events.listen((_) {});
    await second.cancel();
  } on StateError catch (error) {
    say('Одноразовий потік, друга підписка: ${error.message}');
  } finally {
    await first.cancel();
    await single.close();
  }

  final broadcast = ChangeEventBus<ServiceRecord>(broadcast: true);
  var delivered = 0;
  final a = broadcast.events.listen((_) => delivered++);
  final b = broadcast.events.listen((_) => delivered++);
  broadcast.publish(ChangeEvent(ChangeType.added, loadDemoRecords().first));
  await Future<void>.delayed(_pause);
  say('Широкомовний потік: дві підписки, доставлено $delivered копії події');
  await a.cancel();
  await b.cancel();
  await broadcast.close();
}

/// Крок 13. Конвеєр: залишає ідентифікатори перших доданих записів.
Stream<String> buildAddedIdsPipeline(
  Stream<ChangeEvent<ServiceRecord>> source,
) => source
    .where((event) => event.type == ChangeType.added)
    .map((event) => event.entity.id)
    .take(_pipelineLimit);

/// Крок 13. Запускає конвеєр [buildAddedIdsPipeline] над змішаними подіями.
Future<List<String>> demonstratePipeline() async {
  final records = loadDemoRecords();
  final bus = ChangeEventBus<ServiceRecord>();
  bus
    ..publish(ChangeEvent(ChangeType.added, records[0]))
    ..publish(ChangeEvent(ChangeType.updated, records[1]))
    ..publish(ChangeEvent(ChangeType.added, records[2]))
    ..publish(ChangeEvent(ChangeType.removed, records[3]))
    ..publish(ChangeEvent(ChangeType.added, records[4]));
  final closing = bus.close();

  // take завершує потік і скасовує підписку після двох елементів.
  final ids = await buildAddedIdsPipeline(bus.events).toList();
  await closing;
  say('Конвеєр where → map → take: $ids');
  return ids;
}
