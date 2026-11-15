import 'package:fleet_service/fleet_service.dart';

/// Інтервал між елементами потоку в демонстрації `await for`.
const Duration _watchInterval = Duration(milliseconds: 100);

/// Друкує заголовок розділу демонстрації.
void _title(String text) => say('\n=== $text ===');

Future<void> main() async {
  final samples = loadDemoRecords();
  AsyncRepository<ServiceRecord> newRepository() =>
      AsyncRepository<ServiceRecord>(
        streamInterval: _watchInterval,
        initial: samples,
      );

  _title('Крок 3. Забутий await');
  await demonstrateForgottenAwait();

  _title('Крок 4. Послідовно проти одночасно');
  await compareSequentialAndConcurrent();

  _title('Крок 5. Future.wait проти .wait');
  await compareWaitStrategies();

  _title('Крок 6. Неспіймана асинхронна помилка');
  await demonstrateUncaughtAsyncError();

  _title('Крок 7. Генератор async* і await for');
  await consumeWithAwaitFor(newRepository());

  _title('Крок 8. Лінивість генератора');
  await demonstrateLazyGenerator(newRepository());

  _title('Кроки 9–10. Події до підписки; listen і скасування');
  await demonstrateBufferedEvents();

  _title('Крок 11. Помилка всередині потоку');
  await compareErrorHandling();

  _title('Крок 12. Одноразовий і широкомовний потік');
  await compareSingleAndBroadcast();

  _title('Крок 13. Конвеєр трансформації потоку');
  await demonstratePipeline();

  _title('Крок 14. Isolate.run');
  await compareMainAndIsolate();
  await compareParallelIsolates();

  _title('Крок 15. Глобальна змінна в ізоляті');
  await demonstrateGlobalIsolation();
}
