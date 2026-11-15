import '../identifiable.dart';
import 'change_event.dart';
import 'change_event_bus.dart';

/// Затримка однієї операції сховища за замовчуванням.
const Duration defaultLatency = Duration(milliseconds: 300);

/// Інтервал між елементами потоку [AsyncRepository.watchAll] за замовчуванням.
const Duration defaultStreamInterval = Duration(milliseconds: 100);

/// Помилка: сутність з указаним ідентифікатором не знайдено.
class const EntityNotFoundException(
  /// Ідентифікатор, який не знайдено.
  final String id,
) implements Exception {
  @override
  String toString() => 'EntityNotFoundException: сутність «$id» не знайдено';
}

/// Асинхронне сховище сутностей: асинхронний аналог `Repository<T>` із ЛР 2.
///
/// Джерело даних імітується затримками [Future.delayed].
class AsyncRepository<T extends Identifiable> {
  /// Створює сховище.
  ///
  /// [latency] — тривалість кожної операції, [streamInterval] — інтервал
  /// між елементами [watchAll], [changes] — необов'язкова шина подій змін,
  /// [initial] — початковий вміст.
  AsyncRepository({
    this.latency = defaultLatency,
    this.streamInterval = defaultStreamInterval,
    this.changes,
    Iterable<T> initial = const [],
  }) {
    for (final item in initial) {
      _items[item.id] = item;
    }
  }

  /// Тривалість однієї операції.
  final Duration latency;

  /// Інтервал між елементами потоку [watchAll].
  final Duration streamInterval;

  /// Шина, до якої сховище публікує події змін, або `null`.
  final ChangeEventBus<T>? changes;

  final Map<String, T> _items = {};

  /// Поточна кількість сутностей (синхронно, без затримки).
  int get length => _items.length;

  /// Повертає сутність за ідентифікатором [id] або `null`.
  Future<T?> load(String id) async {
    await Future<void>.delayed(latency);
    return _items[id];
  }

  /// Повертає сутність за [id] або кидає [EntityNotFoundException].
  Future<T> loadOrThrow(String id) async {
    final item = await load(id);
    if (item == null) {
      throw EntityNotFoundException(id);
    }
    return item;
  }

  /// Зберігає [item]: додає нову сутність або замінює наявну.
  Future<void> save(T item) async {
    await Future<void>.delayed(latency);
    final isNew = !_items.containsKey(item.id);
    _items[item.id] = item;
    changes?.publish(
      ChangeEvent<T>(isNew ? ChangeType.added : ChangeType.updated, item),
    );
  }

  /// Видаляє сутність за [id]; повертає `true`, якщо вона існувала.
  Future<bool> delete(String id) async {
    await Future<void>.delayed(latency);
    final removed = _items.remove(id);
    if (removed == null) {
      return false;
    }
    changes?.publish(ChangeEvent<T>(ChangeType.removed, removed));
    return true;
  }

  /// Видає сутності по одній у міру «надходження».
  Stream<T> watchAll() async* {
    for (final item in _items.values.toList()) {
      await Future<void>.delayed(streamInterval);
      yield item;
    }
  }
}
