import '../csv_parser.dart';
import '../extensions.dart';
import '../identifiable.dart';
import '../work_type.dart';

/// Запис про обслуговування в «класичному» вигляді — до переписування на
/// первинний конструктор (крок 3 лабораторної роботи).
///
/// Зберігається для порівняння з `ServiceRecord`; поведінка еквівалентна.
class ServiceRecordClassic extends Identifiable with Auditable {
  /// Створює запис із заданих значень.
  const ServiceRecordClassic({
    required this.plate,
    required this.workType,
    required this.mileage,
    required this.date,
    required this.cost,
    required this.performer,
  });

  /// Розбирає рядок `номер;тип;пробіг;дата;вартість;виконавець`; кидає
  /// [FormatException] для некоректного рядка.
  ServiceRecordClassic.fromCsv(String line)
    : this._fromFields(requireFields(line));

  ServiceRecordClassic._fromFields(RecordFields f)
    : this(
        plate: f.plate,
        workType: f.workType,
        mileage: f.mileage,
        date: f.date,
        cost: f.cost,
        performer: f.performer,
      );

  /// Повертає раніше створений об'єкт для рядка [line] або створює новий.
  factory ServiceRecordClassic.cached(String line) =>
      _cache.putIfAbsent(line.trim(), () => ServiceRecordClassic.fromCsv(line));

  static final Map<String, ServiceRecordClassic> _cache = {};

  /// Державний номерний знак автомобіля.
  final String plate;

  /// Тип виконаних робіт.
  final WorkType workType;

  /// Пробіг на момент робіт, км.
  final int mileage;

  /// Дата виконання робіт.
  final DateTime date;

  /// Вартість робіт, грн.
  final double cost;

  /// Виконавець.
  final String performer;

  @override
  String get id => '$plate|${date.isoDate}|${workType.code}';

  @override
  bool operator ==(Object other) =>
      other is ServiceRecordClassic &&
      other.plate == plate &&
      other.workType == workType &&
      other.mileage == mileage &&
      other.date == date &&
      other.cost == cost &&
      other.performer == performer;

  @override
  int get hashCode =>
      Object.hash(plate, workType, mileage, date, cost, performer);

  @override
  String toString() =>
      'ServiceRecord($plate, ${workType.label}, $mileage км, '
      '${date.isoDate}, ${cost.toStringAsFixed(2)} грн, $performer)';
}
