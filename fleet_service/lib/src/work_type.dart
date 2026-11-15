import 'service_category.dart';

/// Тип виконаних робіт; перелічення з полями, конструктором і методами.
enum WorkType(
  /// Короткий код типу у вхідних рядках.
  final String code,

  /// Назва типу для звітів.
  final String label,

  /// Категорія, до якої належить тип робіт.
  final ServiceCategory category,
) {
  /// Заміна моторної оливи й масляного фільтра.
  oilChange('oil', 'Заміна оливи', Routine(intervalKm: 10000)),

  /// Сезонна заміна й балансування коліс.
  tireService('tires', 'Шиномонтаж', Routine(intervalKm: 20000)),

  /// Ремонт гальмівної системи.
  brakeRepair('brakes', 'Ремонт гальм', Repair(complex: false)),

  /// Кузовний ремонт і фарбування.
  bodywork('body', 'Кузовний ремонт', Repair(complex: true)),

  /// Ремонт електрообладнання.
  electrical('electric', 'Електрика', Repair(complex: false)),

  /// Комп'ютерна діагностика.
  diagnostics('diag', 'Діагностика', Inspection()),

  /// Обов'язковий технічний огляд.
  techInspection('inspection', 'Технічний огляд', Inspection());

  /// Повертає тип за кодом [text] без урахування регістру або `null`.
  static WorkType? tryParse(String text) {
    final key = text.trim().toLowerCase();
    return values.where((type) => type.code == key).firstOrNull;
  }

  /// Чи є робота плановою (регламентною).
  bool get isPlanned => category is Routine;
}
