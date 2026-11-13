import 'constants.dart';
import 'service_record.dart';
import 'work_type.dart';

/// Розширення колекції записів для агрегації вартості.
extension ServiceRecordIterable on Iterable<ServiceRecord> {
  /// Сумарна вартість усіх записів, грн.
  double get totalCost => fold(0.0, (sum, record) => sum + record.cost);

  /// Сумарна вартість за типами робіт.
  Map<WorkType, double> get costByWorkType {
    final result = <WorkType, double>{};
    for (final record in this) {
      result.update(
        record.workType,
        (value) => value + record.cost,
        ifAbsent: () => record.cost,
      );
    }
    return result;
  }
}

/// Підсумок за [records]: кількість, сума й середня вартість.
({int count, double total, double average}) summarize(
  Iterable<ServiceRecord> records,
) {
  final count = records.length;
  final total = records.totalCost;
  return (count: count, total: total, average: count == 0 ? 0 : total / count);
}

/// Групує [records] за державним номером.
Map<String, List<ServiceRecord>> groupByPlate(Iterable<ServiceRecord> records) {
  final groups = <String, List<ServiceRecord>>{};
  for (final record in records) {
    groups.putIfAbsent(record.plate, () => []).add(record);
  }
  return groups;
}

/// Цінова категорія запису; використовує зіставлення зі зразком і охоронці.
String costBand(ServiceRecord record) => switch (record) {
  ServiceRecord(cost: final c) when c >= expensiveJobUah => 'дорога робота',
  ServiceRecord(workType: WorkType.oilChange, mileage: final m)
      when m >= highMileageKm =>
    'заміна оливи на високопробіжному авто',
  ServiceRecord(cost: final c) when c >= mediumJobUah => 'середня за ціною',
  _ => 'недорога робота',
};
