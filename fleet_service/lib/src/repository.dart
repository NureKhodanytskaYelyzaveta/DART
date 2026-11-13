import 'identifiable.dart';

/// Сховище сутностей, які вміють повідомляти власний ідентифікатор.
///
/// Обмеження `T extends Identifiable` гарантує компілятору, що в кожного
/// елемента є властивість `id`; без нього `item.id` не скомпілювалося б.
class Repository<T extends Identifiable> {
  final Map<String, T> _items = {};

  /// Кількість збережених елементів.
  int get length => _items.length;

  /// Усі збережені елементи в порядку додавання.
  Iterable<T> get all => _items.values;

  /// Додає [item]; повертає `true`, якщо елемента з таким `id` ще не було.
  ///
  /// Якщо елемент із тим самим `id` уже є, сховище не змінюється, а метод
  /// повертає `false`: дублікат відкидається, перший запис зберігається.
  bool add(T item) {
    if (_items.containsKey(item.id)) {
      return false;
    }
    _items[item.id] = item;
    return true;
  }

  /// Знаходить елемент за ідентифікатором [id] або повертає `null`.
  T? findById(String id) => _items[id];

  /// Елементи, що задовольняють умову [test].
  Iterable<T> where(bool Function(T) test) => _items.values.where(test);
}
