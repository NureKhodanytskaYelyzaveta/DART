/// Функції розбору, перевірки та агрегації журналу обслуговування автопарку.
library;

/// Роздільник полів у вхідному рядку.
const String fieldSeparator = ';';

/// Кількість полів у коректному вхідному рядку.
const int fieldCount = 6;

/// Найраніший допустимий рік обслуговування.
const int minServiceYear = 2000;

/// Максимально допустимий пробіг, км.
const int maxMileage = 2000000;

/// Максимально допустима вартість одного обслуговування, грн.
const double maxCost = 1000000;

/// Поріг вартості, починаючи з якого обслуговування вважається дорогим, грн.
const double expensiveThreshold = 5000;

/// Кількість записів у рейтингу звіту за замовчуванням.
const int defaultTopCount = 5;

/// Роздільник колонок у рядках звіту за замовчуванням.
const String defaultColumnSeparator = ' | ';

/// Запис про обслуговування автомобіля.
typedef ServiceRecord = ({
  String plate,
  String workType,
  int mileage,
  DateTime date,
  double cost,
  String contractor,
});

/// Результат розбору рядка: або запис, або опис помилки.
typedef ParseResult = ({ServiceRecord? record, String? error});

/// Результат завантаження: коректні записи та перелік проблем.
typedef LoadResult = ({List<ServiceRecord> valid, List<String> problems});

/// Підсумок по групі: кількість, сума й середнє значення вартості.
typedef GroupSummary = ({int count, double total, double average});

/// Лічильник оброблених записів: пара функцій над спільною змінною.
typedef Counter = ({void Function() increment, int Function() current});

/// Дата у форматі `РРРР-ММ-ДД` з іменованими групами.
final RegExp isoDatePattern = RegExp(
  r'^(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})$',
);

/// Державний номер України: регіон, чотири цифри, серія.
final RegExp platePattern = RegExp(
  r'^(?<region>[ABCEHIKMOPTX]{2})(?<number>\d{4})(?<series>[ABCEHIKMOPTX]{2})$',
);

/// Номер для маскування: регіон, дві старші цифри, дві молодші, серія.
final RegExp _maskPattern = RegExp(
  r'(?<region>[A-Z]{2})(?<head>\d{2})(?<tail>\d{2})(?<series>[A-Z]{2})',
);

/// Розбирає дату [text] формату `РРРР-ММ-ДД`.
DateTime? parseIsoDate(String text) {
  final match = isoDatePattern.firstMatch(text);
  if (match == null) return null;
  final date = DateTime.tryParse(text);
  if (date == null) return null;
  final sameYear = date.year == int.tryParse(match.namedGroup('year') ?? '');
  final sameMonth = date.month == int.tryParse(match.namedGroup('month') ?? '');
  final sameDay = date.day == int.tryParse(match.namedGroup('day') ?? '');
  return sameYear && sameMonth && sameDay ? date : null;
}

/// Розбирає рядок [line] у запис предметної області.
ParseResult parseLine(String line) {
  final parts = line.split(fieldSeparator).map((p) => p.trim()).toList();
  if (parts.length != fieldCount) {
    return (
      record: null,
      error: 'очікувалось полів: $fieldCount, отримано: ${parts.length}',
    );
  }
  if (parts.any((p) => p.isEmpty)) {
    return (record: null, error: 'є порожнє поле');
  }
  final mileage = int.tryParse(parts[2]);
  if (mileage == null) {
    return (record: null, error: 'пробіг «${parts[2]}» не є цілим числом');
  }
  final date = parseIsoDate(parts[3]);
  if (date == null) {
    return (record: null, error: 'дата «${parts[3]}» некоректна');
  }
  final cost = double.tryParse(parts[4]);
  if (cost == null) {
    return (record: null, error: 'вартість «${parts[4]}» не є числом');
  }
  return (
    record: (
      plate: parts[0].toUpperCase(),
      workType: parts[1],
      mileage: mileage,
      date: date,
      cost: cost,
      contractor: parts[5],
    ),
    error: null,
  );
}

/// Перевіряє формат номера й діапазони значень [record].
List<String> validateRecord(ServiceRecord record, {DateTime? now}) {
  final current = now ?? DateTime.now();
  return [
    if (!platePattern.hasMatch(record.plate))
      'номер «${record.plate}» не відповідає формату AA0000AA',
    if (record.mileage < 0 || record.mileage > maxMileage)
      'пробіг ${record.mileage} км поза межами 0–$maxMileage',
    if (record.cost <= 0 || record.cost > maxCost)
      'вартість ${record.cost} грн поза межами (0; $maxCost]',
    if (record.date.year < minServiceYear) 'дата раніша за $minServiceYear рік',
    if (record.date.isAfter(current)) 'дата обслуговування в майбутньому',
  ];
}

/// Розбирає й перевіряє всі [lines].
LoadResult loadRecords(
  Iterable<String> lines, {
  DateTime? now,
  void Function()? onProcessed,
}) {
  // Матеріалізуємо результат, щоб map виконався один раз.
  final checked = lines.indexed.map((entry) {
    onProcessed?.call();
    final (:record, :error) = parseLine(entry.$2);
    final problems = record == null
        ? [error ?? 'невідома помилка']
        : validateRecord(record, now: now);
    return (number: entry.$1 + 1, record: record, problems: problems);
  }).toList();

  return (
    valid: checked
        .where((c) => c.problems.isEmpty)
        .map((c) => c.record)
        .whereType<ServiceRecord>()
        .toList(),
    problems: checked
        .where((c) => c.problems.isNotEmpty)
        .expand((c) => c.problems.map((p) => 'рядок ${c.number}: $p'))
        .toList(),
  );
}

// Конвеєри: фільтрація, перетворення, згортання

/// Повертає записи від дати [from] з вартістю не нижчою за [threshold].
List<ServiceRecord> filterExpensive(
  Iterable<ServiceRecord> records, {
  required DateTime from,
  double threshold = expensiveThreshold,
}) => records
    .where((r) => !r.date.isBefore(from) && r.cost >= threshold)
    .toList();

/// Перетворює [records] на список текстових описів.
List<String> describeRecords(Iterable<ServiceRecord> records) => records
    .map((r) => '${r.plate}: ${r.workType} (${formatDate(r.date)})')
    .toList();

/// Сумарна вартість [records], грн. Це конвеєр згортання (`fold`).
double totalCost(Iterable<ServiceRecord> records) =>
    records.fold<double>(0, (sum, r) => sum + r.cost);

/// Середня вартість [records]; для порожнього набору — 0.
double averageCost(Iterable<ServiceRecord> records) =>
    records.isEmpty ? 0 : totalCost(records) / records.length;

/// Найдешевше й найдорожче обслуговування; для порожнього набору обидва
({ServiceRecord? cheapest, ServiceRecord? priciest}) costExtremes(
  Iterable<ServiceRecord> records,
) => (
  cheapest: records.fold<ServiceRecord?>(
    null,
    (best, r) => best == null || r.cost < best.cost ? r : best,
  ),
  priciest: records.fold<ServiceRecord?>(
    null,
    (best, r) => best == null || r.cost > best.cost ? r : best,
  ),
);

/// Максимальний пробіг серед [records]; для порожнього набору — 0.
int maxMileageOf(Iterable<ServiceRecord> records) =>
    records.fold<int>(0, (best, r) => r.mileage > best ? r.mileage : best);

/// Останнє за датою обслуговування автомобіля з номером [plate].
ServiceRecord? latestFor(Iterable<ServiceRecord> records, String plate) =>
    sortByDate(records.where((r) => r.plate == plate)).firstOrNull;

// Групування

/// Групує [records] за типом робіт.
Map<String, List<ServiceRecord>> groupByWorkType(
  Iterable<ServiceRecord> records,
) => records.fold<Map<String, List<ServiceRecord>>>({}, (groups, r) {
  (groups[r.workType] ??= []).add(r);
  return groups;
});

/// Підсумок (кількість, сума, середнє) для кожної групи.
Map<String, GroupSummary> summarizeGroups(
  Map<String, List<ServiceRecord>> groups,
) => groups.map(
  (key, list) => MapEntry(key, (
    count: list.length,
    total: totalCost(list),
    average: averageCost(list),
  )),
);

// Сортування

/// Повертає нову відсортовану копію [records] за числовим ключем [key].
List<ServiceRecord> sortRecords(
  Iterable<ServiceRecord> records,
  num Function(ServiceRecord record) key, {
  bool ascending = false,
}) {
  final sorted = [...records];
  sorted.sort((a, b) {
    final byKey = ascending
        ? key(a).compareTo(key(b))
        : key(b).compareTo(key(a));
    if (byKey != 0) return byKey;
    final byPlate = a.plate.compareTo(b.plate);
    return byPlate != 0 ? byPlate : a.date.compareTo(b.date);
  });
  return sorted;
}

/// Сортування за вартістю (критерій 1).
List<ServiceRecord> sortByCost(
  Iterable<ServiceRecord> records, {
  bool ascending = false,
}) => sortRecords(records, (r) => r.cost, ascending: ascending);

/// Сортування за пробігом (критерій 2).
List<ServiceRecord> sortByMileage(
  Iterable<ServiceRecord> records, {
  bool ascending = false,
}) => sortRecords(records, (r) => r.mileage, ascending: ascending);

/// Сортування за датою: за замовчуванням від найновіших до найстаріших.
List<ServiceRecord> sortByDate(
  Iterable<ServiceRecord> records, {
  bool ascending = false,
}) => sortRecords(
  records,
  (r) => r.date.millisecondsSinceEpoch,
  ascending: ascending,
);

// Рядки, замикання, регулярні вирази, дати

/// Форматує [date] як `РРРР-ММ-ДД`.
String formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Форматує суму [amount] як «1234.50 грн».
String formatMoney(double amount) => '${amount.toStringAsFixed(2)} грн';

/// Формує текстовий звіт за списком [records].
String buildReport(
  List<ServiceRecord> records, {
  int topCount = defaultTopCount,
  bool ascending = false,
  String separator = defaultColumnSeparator,
}) {
  final buffer = StringBuffer()
    ..writeln('Записів: ${records.length}')
    ..writeln('Сумарна вартість: ${formatMoney(totalCost(records))}')
    ..writeln('Середня вартість: ${formatMoney(averageCost(records))}')
    ..writeln('Рейтинг за вартістю (топ-$topCount):');
  final top = sortByCost(records, ascending: ascending).take(topCount);
  for (final (index, r) in top.indexed) {
    buffer.writeln(
      [
        '${index + 1}. ${r.plate}',
        r.workType,
        formatDate(r.date),
        formatMoney(r.cost),
      ].join(separator),
    );
  }
  return buffer.toString();
}

/// Створює лічильник оброблених записів.
Counter makeCounter() {
  var count = 0;
  return (increment: () => count++, current: () => count);
}

/// Створює предикат «вартість не нижча за [threshold]».
bool Function(ServiceRecord record) costAtLeast(double threshold) =>
    (record) => record.cost >= threshold;

/// Маскує державний номер: `AX1234BH` → `AX12**BH`.
String maskPlate(String text) => text.replaceAllMapped(_maskPattern, (m) {
  // Перевіряємо тип, щоб отримати доступ до іменованих груп.
  if (m is! RegExpMatch) return m[0] ?? '';
  return '${m.namedGroup('region')}${m.namedGroup('head')}**'
      '${m.namedGroup('series')}';
});

/// Скільки повних діб минуло від обслуговування [record] до моменту [now].
int daysSinceService(ServiceRecord record, {DateTime? now}) =>
    (now ?? DateTime.now()).difference(record.date).inDays;