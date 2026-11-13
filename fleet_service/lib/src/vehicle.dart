import 'identifiable.dart';

/// Автомобіль автопарку.
///
/// Приклад класу з іншої гілки, ніж запис про обслуговування: має власний
/// ідентифікатор і так само отримує домішку [Auditable].
class const Vehicle(
  /// Державний номерний знак.
  final String plate,

  /// Марка й модель.
  final String model,

  /// Рік випуску.
  final int year,
) extends Identifiable with Auditable {
  @override
  String get id => plate;

  @override
  String toString() => 'Vehicle($plate, $model, $year)';
}
