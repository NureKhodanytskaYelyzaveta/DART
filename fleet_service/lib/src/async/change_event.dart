import '../identifiable.dart';

/// Вид зміни стану сховища.
enum ChangeType {
  /// Сутність додано.
  added,

  /// Наявну сутність оновлено.
  updated,

  /// Сутність видалено.
  removed,
}

/// Подія зміни стану сутності [T] у сховищі.
class const ChangeEvent<T extends Identifiable>(
  /// Вид зміни.
  final ChangeType type,

  /// Сутність, якої стосується зміна.
  final T entity,
) {
  @override
  bool operator ==(Object other) =>
      other is ChangeEvent<T> && other.type == type && other.entity == entity;

  @override
  int get hashCode => Object.hash(type, entity);

  @override
  String toString() => 'ChangeEvent(${type.name}, ${entity.id})';
}
