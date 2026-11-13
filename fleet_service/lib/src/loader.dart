import 'service_record.dart';

/// Результат завантаження: коректні записи та описи помилок розбору.
typedef LoadResult = ({List<ServiceRecord> records, List<String> errors});

/// Завантажує записи з рядків [lines] без винятків.
///
/// Для кожного некоректного рядка до `errors` додається опис із номером
/// рядка (нумерація з 1).
LoadResult loadRecords(Iterable<String> lines) {
  final records = <ServiceRecord>[];
  final errors = <String>[];
  var number = 0;
  for (final line in lines) {
    number++;
    final (:record, :error) = ServiceRecord.tryParse(line);
    if (record == null) {
      errors.add('рядок $number: $error');
    } else {
      records.add(record);
    }
  }
  return (records: records, errors: errors);
}
