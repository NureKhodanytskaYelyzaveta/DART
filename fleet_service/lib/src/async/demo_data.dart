import '../loader.dart';
import '../sample_data.dart';
import '../service_record.dart';

/// Коректні записи з [sampleLines], розібрані без винятків.
///
/// Повторюваний рядок із початку журналу дає запис із тим самим `id`, що й
/// перший; решта записів мають різні ідентифікатори.
List<ServiceRecord> loadDemoRecords() => loadRecords(sampleLines).records;
