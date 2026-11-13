import 'constants.dart';
import 'extensions.dart';
import 'work_type.dart';

/// Розібрані поля запису; використовується конструкторами класів-записів.
typedef RecordFields = ({
  String plate,
  WorkType workType,
  int mileage,
  DateTime date,
  double cost,
  String performer,
});

/// Розбирає рядок [line] без винятків.
///
/// Повертає запис із двох полів: або `fields`, або опис помилки `error`.
({RecordFields? fields, String? error}) parseFields(String line) {
  final parts = line.split(csvSeparator).map((part) => part.trim()).toList();
  if (parts.length != csvFieldCount) {
    return (
      fields: null,
      error: 'очікувалось $csvFieldCount полів, отримано ${parts.length}',
    );
  }
  final [plate, typeCode, mileageText, dateText, costText, performer] = parts;
  if (plate.isEmpty || performer.isEmpty) {
    return (fields: null, error: 'порожній держномер або виконавець');
  }
  final workType = WorkType.tryParse(typeCode);
  if (workType == null) {
    return (fields: null, error: 'невідомий тип робіт «$typeCode»');
  }
  final mileage = int.tryParse(mileageText);
  if (mileage == null) {
    return (fields: null, error: 'пробіг не є цілим числом: «$mileageText»');
  }
  // DateTime.tryParse «виправляє» неіснуючі дні (30 лютого), тому дату
  // додатково порівнюємо з вихідним текстом.
  final date = DateTime.tryParse(dateText);
  if (date == null || date.isoDate != dateText) {
    return (fields: null, error: 'некоректна дата «$dateText»');
  }
  final cost = double.tryParse(costText);
  if (cost == null || !cost.isFinite) {
    return (fields: null, error: 'вартість не є числом: «$costText»');
  }
  return (
    fields: (
      plate: plate,
      workType: workType,
      mileage: mileage,
      date: date,
      cost: cost,
      performer: performer,
    ),
    error: null,
  );
}

/// Розбирає рядок [line] або кидає [FormatException].
///
/// Призначена для конструкторів, які не можуть повернути `null`.
RecordFields requireFields(String line) {
  final (:fields, :error) = parseFields(line);
  if (fields == null) {
    throw FormatException(error ?? 'невідома помилка розбору', line);
  }
  return fields;
}
