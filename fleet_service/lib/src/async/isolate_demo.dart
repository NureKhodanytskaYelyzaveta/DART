import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../sample_data.dart';
import 'console.dart';

/// Кількість згенерованих записів у важкому обчисленні.
const int syntheticRecordCount = 20000000;

/// Кількість однакових завдань у порівнянні «головний ізолят / ізоляти».
const int _parallelTasks = 4;

/// Інтервал таймера, яким перевіряється «живість» головного ізолята.
const Duration _tickInterval = Duration(milliseconds: 10);

const int _initialSeed = 42;
const int _lcgMultiplier = 1103515245;
const int _lcgIncrement = 12345;
const int _lcgMask = 0x7fffffff;
const int _baseCost = 100;
const int _costShift = 8;
const int _costSpread = 5000;

/// Крок розрахунку лічильника в демонстрації ізоляції глобальних змінних.
const int _counterStep = 10;

/// Номери автомобілів автопарку з навчальних даних.
final List<String> _plates = [for (final car in sampleVehicles) car.plate];

/// Глобальний лічильник: кожен ізолят має власну копію цієї змінної.
int processedCounter = 0;

/// Підсумовує вартість [count] згенерованих записів за номерними знаками.
///
/// Дані формує детермінований генератор псевдовипадкових чисел, тому
/// результат однаковий у будь-якому ізоляті. Обчислення синхронне й важке.
Map<String, double> aggregateCostByPlate(int count) {
  final totals = <String, double>{};
  var seed = _initialSeed;
  for (var i = 0; i < count; i++) {
    seed = (seed * _lcgMultiplier + _lcgIncrement) & _lcgMask;
    final plate = _plates[seed % _plates.length];
    final cost = (_baseCost + (seed >> _costShift) % _costSpread).toDouble();
    totals[plate] = (totals[plate] ?? 0.0) + cost;
  }
  return totals;
}

/// Час виконання та кількість «тиків» таймера за цей час.
typedef Measurement = ({Duration elapsed, int ticks});

Future<Measurement> _measure(FutureOr<Object?> Function() job) async {
  var ticks = 0;
  final timer = Timer.periodic(_tickInterval, (_) => ticks++);
  // Даємо таймеру стартувати до початку вимірювання.
  await Future<void>.delayed(_tickInterval * 2);
  ticks = 0;
  final watch = Stopwatch()..start();
  await job();
  watch.stop();
  timer.cancel();
  return (elapsed: watch.elapsed, ticks: ticks);
}

/// Крок 14. Порівнює обчислення в головному ізоляті та в `Isolate.run`.
Future<({Measurement inMain, Measurement inIsolate})> compareMainAndIsolate({
  int count = syntheticRecordCount,
}) async {
  final inMain = await _measure(() => aggregateCostByPlate(count));
  final inIsolate = await _measure(
    () => Isolate.run(() => aggregateCostByPlate(count)),
  );
  say(
    'Головний ізолят: ${inMain.elapsed.inMilliseconds} мс, '
    'тиків таймера: ${inMain.ticks}',
  );
  say(
    'Isolate.run: ${inIsolate.elapsed.inMilliseconds} мс, '
    'тиків таймера: ${inIsolate.ticks}',
  );
  return (inMain: inMain, inIsolate: inIsolate);
}

/// Крок 14. Чотири однакові завдання: послідовно в головному ізоляті
/// проти чотирьох ізолятів одночасно.
Future<({Duration sequentialInMain, Duration parallelInIsolates})>
compareParallelIsolates({int count = syntheticRecordCount}) async {
  final watch = Stopwatch()..start();
  for (var i = 0; i < _parallelTasks; i++) {
    aggregateCostByPlate(count);
  }
  final sequentialInMain = watch.elapsed;

  watch
    ..reset()
    ..start();
  await Future.wait(
    List.generate(
      _parallelTasks,
      (_) => Isolate.run(() => aggregateCostByPlate(count)),
    ),
  );
  final parallelInIsolates = watch.elapsed;

  say('Доступно ядер процесора: ${Platform.numberOfProcessors}');
  say(
    '$_parallelTasks завдання послідовно в головному ізоляті: '
    '${sequentialInMain.inMilliseconds} мс',
  );
  say(
    '$_parallelTasks завдання в $_parallelTasks ізолятах: '
    '${parallelInIsolates.inMilliseconds} мс',
  );
  return (
    sequentialInMain: sequentialInMain,
    parallelInIsolates: parallelInIsolates,
  );
}

/// Крок 15. Змінює [processedCounter] усередині `Isolate.run`.
///
/// Повертає значення лічильника в ізоляті та в головному ізоляті після змін.
Future<({int insideIsolate, int inMain})> demonstrateGlobalIsolation() async {
  final insideIsolate = await Isolate.run(() {
    processedCounter += _counterStep;
    return processedCounter;
  });
  final inMain = processedCounter;
  say('Лічильник усередині ізолята: $insideIsolate');
  say('Лічильник у головному ізоляті: $inMain');
  return (insideIsolate: insideIsolate, inMain: inMain);
}
