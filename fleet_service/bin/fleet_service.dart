import 'dart:io';

import 'package:fleet_service/fleet_service.dart';
import 'package:fleet_service/src/legacy/record_without_hash.dart';
import 'package:fleet_service/src/legacy/service_record_classic.dart';

/// Умовна «поточна» дата, щоб вивід програми був відтворюваним.
final DateTime today = DateTime(2026, 11, 5);

/// Пробіг, для якого виводиться таблиця наступних робіт, км.
const int demoMileageKm = 100000;

/// Кількість записів у демонстрації зразків із `when`.
const int previewCount = 8;

/// Ширини колонок таблиць виводу.
const int monthsWidth = 2;
const int labelWidth = 16;
const int titleWidth = 24;
const int enumNameWidth = 15;
const int codeWidth = 10;
const int shortLabelWidth = 15;

void out(Object? value) => stdout.writeln(value);

void section(String title) => out('\n=== $title ===');

void main() {
  final (:records, :errors) = loadRecords(sampleLines);

  section('Крок 1–2. Розбір рядків: fromCsv, tryParse, cached');
  out('Прочитано рядків: ${sampleLines.length}');
  out('Коректних записів: ${records.length}');
  out('Помилки розбору (${errors.length}):');
  errors.forEach(out);
  out('Перший запис: ${records.first}');
  final first = ServiceRecord.cached(sampleLines.first);
  final again = ServiceRecord.cached(sampleLines.first);
  out('cached повертає той самий екземпляр: ${identical(first, again)}');
  out(
    'fromCsv повертає той самий екземпляр: '
    '${identical(first, ServiceRecord.fromCsv(sampleLines.first))}',
  );
  out(
    'Для некоректного рядка fromCsv кидає виняток: '
    '${_tryFromCsv(sampleLines[3])}',
  );

  section('Крок 3. Первинний конструктор проти класичного');
  final classic = ServiceRecordClassic.fromCsv(sampleLines.first);
  out('Рядкові подання збігаються: ${classic.toString() == first.toString()}');
  out('id збігаються: ${classic.id == first.id}');

  section('Крок 4. Рівність і hashCode');
  final a = RecordWithoutHash('AX1234BB', 85400);
  final b = RecordWithoutHash('AX1234BB', 85400);
  out('Без hashCode: a == b → ${a == b}, розмір Set → ${{a, b}.length}');
  final c = ServiceRecord.fromCsv(sampleLines.first);
  final d = ServiceRecord.fromCsv(sampleLines.first);
  out('З hashCode:   c == d → ${c == d}, розмір Set → ${{c, d}.length}');

  section('Крок 5–6. Запечатана ієрархія й switch без default');
  out('Для пробігу $demoMileageKm км; «далі» — пробіг наступної роботи:');
  for (final type in WorkType.values) {
    final category = type.category;
    final months = warrantyMonths(category).toString().padLeft(monthsWidth);
    out(
      '${type.label.padRight(labelWidth)} ${category.title.padRight(titleWidth)} '
      'гар. $months міс., далі: ${category.nextDueKm(demoMileageKm) ?? "—"}',
    );
  }

  section('Крок 7. Домішка Auditable (on Identifiable)');
  out(first.auditTag);
  out(sampleVehicles.first.auditTag);

  section('Крок 8. Методи розширення');
  out(
    'isValidPlate: AX1234BB → ${"AX1234BB".isValidPlate}, '
    '12345 → ${"12345".isValidPlate}',
  );
  out('maskedPlate: ${"AX1234BB".maskedPlate}');
  out(
    'Вік першого запису: ${first.date.daysSince(DateTime(2025, 1, 1))} діб '
    'після 1 січня 2025; ${first.ageInDays(today)} діб до ${today.isoDate}',
  );
  out('Сумарна вартість: ${records.totalCost.toStringAsFixed(2)} грн');

  section('Крок 9. Узагальнене сховище Repository<T>');
  final recordRepo = Repository<ServiceRecord>();
  var added = 0;
  for (final record in records) {
    if (recordRepo.add(record)) {
      added++;
    }
  }
  out('Додано нових: $added з ${records.length} (дублікат за id відкинуто)');
  final vehicleRepo = Repository<Vehicle>()..add(sampleVehicles[0]);
  sampleVehicles.skip(1).forEach(vehicleRepo.add);
  out('Автомобілів у сховищі: ${vehicleRepo.length}');
  out('findById(KA5678CE): ${vehicleRepo.findById("KA5678CE")}');
  out('findById(ZZ0000ZZ): ${vehicleRepo.findById("ZZ0000ZZ")}');
  final expensive = recordRepo.where((r) => r.cost >= expensiveJobUah);
  out('Дорогих робіт: ${expensive.length}');

  section('Крок 10. Перелічення WorkType із членами');
  for (final type in WorkType.values) {
    out(
      '${type.name.padRight(enumNameWidth)} код=${type.code.padRight(codeWidth)} '
      'планова=${type.isPlanned}',
    );
  }
  out('tryParse("BODY") → ${WorkType.tryParse("BODY")}');

  section('Крок 11. Записи (records) і деструктуризація');
  final (:count, :total, :average) = summarize(recordRepo.all);
  out(
    'Записів: $count, сума: ${total.toStringAsFixed(2)} грн, '
    'середня: ${average.toStringAsFixed(2)} грн',
  );
  final byPlate = groupByPlate(recordRepo.all);
  for (final MapEntry(key: plate, value: items) in byPlate.entries) {
    out(
      '${plate.maskedPlate}: ${items.length} зап., '
      '${items.totalCost.toStringAsFixed(2)} грн',
    );
  }

  section('Крок 12. Зіставлення зі зразком і охоронцями (when)');
  for (final record in recordRepo.all.take(previewCount)) {
    out(
      '${record.plate} ${record.workType.label.padRight(shortLabelWidth)} → '
      '${costBand(record)}',
    );
  }

  section('Валідація діапазонів');
  for (final record in recordRepo.all) {
    final problems = record.validate(today: today);
    if (problems.isNotEmpty) {
      out('${record.id}: ${problems.join("; ")}');
    }
  }
}

String _tryFromCsv(String line) {
  try {
    ServiceRecord.fromCsv(line);
    return 'не кинув';
  } on FormatException catch (e) {
    return 'FormatException: ${e.message}';
  }
}
