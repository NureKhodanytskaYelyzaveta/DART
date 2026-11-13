import 'constants.dart';

/// Категорія виконаних робіт; запечатана ієрархія з трьох підтипів.
sealed class ServiceCategory {
  /// Створює категорію.
  const ServiceCategory();

  /// Назва категорії для звіту.
  String get title;

  /// Пробіг, на якому потрібна наступна подібна робота, або `null`, якщо
  /// наступна робота не планується. [mileageKm] — пробіг під час виконання.
  int? nextDueKm(int mileageKm);
}

/// Планове обслуговування за регламентом виробника.
final class Routine extends ServiceCategory {
  /// Створює планове обслуговування з інтервалом [intervalKm].
  const Routine({required this.intervalKm});

  /// Регламентний інтервал між роботами, км.
  final int intervalKm;

  @override
  String get title => 'Планове обслуговування';

  @override
  int? nextDueKm(int mileageKm) => mileageKm + intervalKm;
}

/// Ремонт, потреба в якому виникла внаслідок несправності.
final class Repair extends ServiceCategory {
  /// Створює ремонт; [complex] позначає складний ремонт.
  const Repair({required this.complex});

  /// Ознака складного ремонту (збільшує гарантійний термін).
  final bool complex;

  @override
  String get title => complex ? 'Складний ремонт' : 'Ремонт';

  @override
  int? nextDueKm(int mileageKm) => null;
}

/// Огляд або діагностика без заміни вузлів.
final class Inspection extends ServiceCategory {
  /// Створює огляд.
  const Inspection();

  @override
  String get title => 'Огляд і діагностика';

  @override
  int? nextDueKm(int mileageKm) => mileageKm + inspectionIntervalKm;
}

/// Гарантійний термін на роботи категорії [category], місяців.
///
/// Вираз `switch` не має гілки `default`: компілятор перевіряє вичерпність
/// за запечатаною ієрархією.
int warrantyMonths(ServiceCategory category) => switch (category) {
  Routine() => routineWarrantyMonths,
  Repair(complex: true) => complexRepairWarrantyMonths,
  Repair() => simpleRepairWarrantyMonths,
  Inspection() => 0,
};
