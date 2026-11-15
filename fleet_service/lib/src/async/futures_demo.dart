import 'dart:async';

import '../service_record.dart';
import 'async_repository.dart';
import 'console.dart';
import 'demo_data.dart';

/// Затримка операції в демонстраціях «забутого await» і помилок.
const Duration _demoLatency = Duration(milliseconds: 200);

/// Тривалість однієї «повільної» операції для порівняння часу виконання.
const Duration _slowOperation = Duration(milliseconds: 500);

/// Кількість операцій у порівнянні послідовного й одночасного виконання.
const int _operationCount = 3;

/// Ідентифікатор, якого немає в сховищі.
const String _missingId = 'НЕМАЄ|такого|запису';

/// Крок 3. Показує, що змінюється, коли забути `await` перед `save`.
Future<void> demonstrateForgottenAwait() async {
  final samples = loadDemoRecords();
  final repository = AsyncRepository<ServiceRecord>(latency: _demoLatency);

  // Навмисна помилка: виклик без await. Правило unawaited_futures
  // підсвічує цей рядок, тому його приглушено лише тут.
  // ignore: unawaited_futures
  repository.save(samples[0]);
  say('Без await: одразу після save() у сховищі ${repository.length} записів');
  await Future<void>.delayed(_demoLatency * 2);
  say('Без await: після очікування у сховищі ${repository.length} записів');

  await repository.save(samples[1]);
  say('З await: одразу після save() у сховищі ${repository.length} записів');
}

/// Результат порівняння послідовного й одночасного виконання.
typedef TimingComparison = ({Duration sequential, Duration concurrent});

/// Крок 4. Вимірює три операції по 500 мс: послідовно та через `Future.wait`.
Future<TimingComparison> compareSequentialAndConcurrent() async {
  final samples = loadDemoRecords();
  final repository = AsyncRepository<ServiceRecord>(
    latency: _slowOperation,
    initial: samples,
  );
  final ids = samples.take(_operationCount).map((r) => r.id).toList();

  final watch = Stopwatch()..start();
  for (final id in ids) {
    await repository.load(id);
  }
  final sequential = watch.elapsed;

  watch
    ..reset()
    ..start();
  await Future.wait(ids.map(repository.load));
  final concurrent = watch.elapsed;

  say('Послідовно (3 × await): ${sequential.inMilliseconds} мс');
  say('Одночасно (Future.wait): ${concurrent.inMilliseconds} мс');
  return (sequential: sequential, concurrent: concurrent);
}

/// Крок 5. Порівнює обробку помилки в `Future.wait` і в розширенні `.wait`.
Future<void> compareWaitStrategies() async {
  final samples = loadDemoRecords();
  final repository = AsyncRepository<ServiceRecord>(
    latency: _demoLatency,
    initial: samples,
  );

  // Три операції стартують одночасно; друга завершиться помилкою.
  List<Future<ServiceRecord?>> startOperations() => [
    repository.load(samples[0].id),
    repository.loadOrThrow(_missingId),
    repository.load(samples[1].id),
  ];

  try {
    await Future.wait(startOperations());
  } on EntityNotFoundException catch (error) {
    say('Future.wait: доступна лише одна помилка: $error');
    say('Future.wait: результати двох успішних операцій втрачено');
  }

  try {
    await startOperations().wait;
  } on ParallelWaitError<List<ServiceRecord?>, List<AsyncError?>> catch (
    error
  ) {
    say('.wait: значення: ${error.values.map((r) => r?.id).toList()}');
    say('.wait: помилки: ${error.errors.map((e) => e?.error).toList()}');
  }
}

/// Крок 6. Показує, що `try/catch` не ловить помилку виклику без `await`.
///
/// Помилка потрапляє не в `catch`, а в обробник неспійманих помилок зони.
Future<void> demonstrateUncaughtAsyncError() async {
  final repository = AsyncRepository<ServiceRecord>(latency: _demoLatency);
  final reported = Completer<void>();

  runZonedGuarded(
    () {
      try {
        // Виклик без await: помилка живе всередині Future, а не кидається
        // синхронно, тому catch нижче її не побачить.
        // ignore: discarded_futures
        repository.loadOrThrow(_missingId);
      } on EntityNotFoundException catch (error) {
        say('try/catch спіймав: $error (цього не станеться)');
      }
      say('try/catch завершився без помилок: виклик не чекав на результат');
    },
    (error, stack) {
      say('Зона отримала неспійману помилку: $error');
      reported.complete();
    },
  );

  await reported.future;
}
