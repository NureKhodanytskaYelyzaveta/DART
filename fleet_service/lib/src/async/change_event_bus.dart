import 'dart:async';

import '../identifiable.dart';
import 'change_event.dart';

/// Шина подій змін: джерело потоку [ChangeEvent] на основі [StreamController].
///
/// За замовчуванням потік одноразової підписки: події, додані до підписки,
/// буферизуються. З параметром `broadcast: true` потік широкомовний:
/// підписників може бути кілька, але події без підписників губляться.
class ChangeEventBus<T extends Identifiable> {
  /// Створює шину; [broadcast] обирає вид потоку.
  ChangeEventBus({bool broadcast = false})
    : _controller = broadcast
          ? StreamController<ChangeEvent<T>>.broadcast()
          : StreamController<ChangeEvent<T>>();

  final StreamController<ChangeEvent<T>> _controller;

  /// Потік подій. Підписник зобов'язаний скасувати свою підписку.
  Stream<ChangeEvent<T>> get events => _controller.stream;

  /// Чи є потік широкомовним.
  bool get isBroadcast => _controller.stream.isBroadcast;

  /// Публікує подію [event].
  void publish(ChangeEvent<T> event) => _controller.add(event);

  /// Додає в потік помилку [error] як окрему подію.
  void publishError(Object error) => _controller.addError(error);

  /// Закриває шину. Повернений [Future] завершується, коли потік завершено.
  Future<void> close() => _controller.close();
}
