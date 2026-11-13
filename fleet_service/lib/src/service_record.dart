import 'constants.dart';
import 'csv_parser.dart';
import 'extensions.dart';
import 'identifiable.dart';
import 'service_category.dart';
import 'work_type.dart';

/// Запис про технічне обслуговування або ремонт автомобіля автопарку.
///
/// Об'єкт незмінний: усі поля `final`, конструктор константний. Рівність
/// визначається значеннями всіх полів.
class const ServiceRecord({
  /// Державний номерний знак автомобіля.
  required final String plate,

  /// Тип виконаних робіт.
  required final WorkType workType,

  /// Пробіг автомобіля на момент робіт, км.
  required final int mileage,

  /// Дата виконання робіт.
  required final DateTime date,

  /// Вартість робіт, грн.
  required final double cost,

  /// Виконавець (СТО або майстер).
  required final String performer,
}) extends Identifiable with Auditable {
  /// Розбирає рядок формату `номер;тип;пробіг;дата;вартість;виконавець`.
  ///
  /// Кидає [FormatException], якщо рядок некоректний; для очікуваних помилок
  /// користуйтеся [ServiceRecord.tryParse].
  ServiceRecord.fromCsv(String line) : this._fromFields(requireFields(line));

  ServiceRecord._fromFields(RecordFields f)
    : this(
        plate: f.plate,
        workType: f.workType,
        mileage: f.mileage,
        date: f.date,
        cost: f.cost,
        performer: f.performer,
      );

  /// Повертає раніше створений об'єкт для того самого рядка [line] або
  /// створює новий і запам'ятовує його.
  factory ServiceRecord.cached(String line) =>
      _cache.putIfAbsent(line.trim(), () => ServiceRecord.fromCsv(line));

  static final Map<String, ServiceRecord> _cache = {};

  /// Розбирає [line] без винятків: повертає або `record`, або опис `error`.
  static ({ServiceRecord? record, String? error}) tryParse(String line) {
    final (:fields, :error) = parseFields(line);
    if (fields == null) {
      return (record: null, error: error);
    }
    return (record: ServiceRecord._fromFields(fields), error: null);
  }

  @override
  String get id => '$plate|${date.isoDate}|${workType.code}';

  /// Категорія виконаних робіт.
  ServiceCategory get category => workType.category;

  /// Пробіг, на якому потрібна наступна подібна робота, або `null`.
  int? get nextDueKm => category.nextDueKm(mileage);

  /// Вік запису в добах станом на [now].
  int ageInDays(DateTime now) => now.difference(date).inDays;

  /// Перелік порушень допустимих діапазонів станом на [today]; порожній
  /// список означає, що запис коректний.
  List<String> validate({required DateTime today}) {
    final problems = <String>[];
    if (!plate.isValidPlate) {
      problems.add('некоректний держномер «$plate»');
    }
    if (mileage <= 0 || mileage > maxMileageKm) {
      problems.add('пробіг $mileage км поза діапазоном 1…$maxMileageKm');
    }
    if (cost <= 0 || cost > maxCostUah) {
      problems.add('вартість $cost грн поза діапазоном');
    }
    if (date.isAfter(today)) {
      problems.add('дата ${date.isoDate} у майбутньому');
    }
    return problems;
  }

  @override
  bool operator ==(Object other) =>
      other is ServiceRecord &&
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
