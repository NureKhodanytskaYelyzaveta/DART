import 'package:fleet_service/fleet_service.dart';
import 'package:fleet_service/service_data.dart';

/// Кількість записів у прикладах сортування.
const int sampleCount = 3;

/// Номер автомобіля, для якого шукається останнє обслуговування.
const String samplePlate = 'KA4321AA';

void main() {
  final now = DateTime.now();
  final processed = makeCounter();

  print('\n1. Завантаження та перевірка');
  final (:valid, :problems) = loadRecords(
    rawRecords,
    now: now,
    onProcessed: processed.increment,
  );
  print('Оброблено рядків: ${processed.current()}');
  print('Коректних записів: ${valid.length}');
  print('Відхилено записів: ${processed.current() - valid.length}');
  print('Виявлено порушень: ${problems.length}');
  problems.forEach(print);

  print('\n2. Конвеєри');
  final expensive = filterExpensive(valid, from: DateTime(2024, 6));
  print('where  — від 2024-06-01 і від ${formatMoney(expensiveThreshold)}:');
  describeRecords(expensive).forEach((t) => print('  $t'));
  print('fold   — сумарна вартість: ${formatMoney(totalCost(valid))}');
  print('fold   — середня вартість: ${formatMoney(averageCost(valid))}');
  final (:cheapest, :priciest) = costExtremes(valid);
  print('fold   — найдешевше: ${cheapest?.workType} (${cheapest?.plate})');
  print('fold   — найдорожче: ${priciest?.workType} (${priciest?.plate})');
  print('fold   — максимальний пробіг: ${maxMileageOf(valid)} км');
  final latest = latestFor(valid, samplePlate);
  print('пошук  — останнє для $samplePlate: ${latest?.workType}');
  print('пошук  — для ZZ0000ZZ: ${latestFor(valid, 'ZZ0000ZZ')}');

  print('\n3. Групування за типом робіт');
  final groups = groupByWorkType(valid);
  summarizeGroups(groups).forEach((type, s) {
    print(
      '${type.padRight(28)} ${s.count} шт., разом ${formatMoney(s.total)}, '
      'середнє ${formatMoney(s.average)}',
    );
  });

  print('\n4. Сортування');
  print('За вартістю (спадання):');
  describeRecords(sortByCost(valid).take(sampleCount))
      .forEach((t) => print('  $t'));
  print('За пробігом (зростання):');
  describeRecords(sortByMileage(valid, ascending: true).take(sampleCount))
      .forEach((t) => print('  $t'));

  print('\n5. Звіт');
  print(buildReport(valid));
  print(buildReport(valid, topCount: 3, ascending: true, separator: ' ; '));

  print('\n6. Замикання');
  final isPricey = costAtLeast(10000);
  print(
    'Вартість від 10000: '
    '${describeRecords(valid.where(isPricey)).toList()}',
  );

  print('\n7. Регулярні вирази');
  valid.map((r) => r.plate).toSet().take(sampleCount).forEach((plate) {
    print('$plate → ${maskPlate(plate)}');
  });
  print(maskPlate('Авто AX1234BH і KA7788IO у ремонті'));
  final plateMatch = platePattern.firstMatch('AX1234BH');
  print(
    'Групи номера: регіон=${plateMatch?.namedGroup('region')}, '
    'число=${plateMatch?.namedGroup('number')}, '
    'серія=${plateMatch?.namedGroup('series')}',
  );

  print('\n8. Арифметика дат');
  for (final r in sortByDate(valid).take(sampleCount)) {
    print(
      '${r.plate}, ${r.workType}: ${daysSinceService(r, now: now)} діб тому',
    );
  }
}