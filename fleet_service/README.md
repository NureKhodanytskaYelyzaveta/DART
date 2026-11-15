# fleet_service — технічне обслуговування автопарку

Лабораторні роботи 2–3 з дисципліни «Програмування мовою Dart»
(варіант 15, наскрізний проєкт; опорна версія SDK — Dart 3.13).

Консольний застосунок будує об'єктно-орієнтовану модель записів про
технічне обслуговування автомобілів: **держномер, тип робіт, пробіг, дата,
вартість, виконавець**. Це та сама предметна область, що й у лабораторній
роботі 1, але дані тепер представлено класами, а не записами й функціями.

## Запуск

```bash
dart pub get
dart run bin/fleet_service.dart
dart analyze
dart format --output=none --set-exit-if-changed .
dart fix --dry-run
```

## Структура

| Файл | Призначення |
| --- | --- |
| `bin/fleet_service.dart` | Точка входу: послідовно демонструє кроки 1–12 завдання. |
| `lib/fleet_service.dart` | Публічний «барель» бібліотеки (`export`). |
| `lib/src/service_record.dart` | Незмінна сутність `ServiceRecord` (первинний конструктор, `fromCsv`, `tryParse`, `cached`, `==`/`hashCode`). |
| `lib/src/legacy/service_record_classic.dart` | Попередня («класична») версія сутності, збережена для порівняння (крок 3). |
| `lib/src/legacy/record_without_hash.dart` | Навчальний клас для експерименту з `==` без `hashCode` (крок 4). |
| `lib/src/service_category.dart` | `sealed class ServiceCategory` і підтипи `Routine`, `Repair`, `Inspection`; `switch` без `default`. |
| `lib/src/work_type.dart` | Перелічення `WorkType` із полями, конструктором і методами. |
| `lib/src/identifiable.dart` | Абстрактний `Identifiable` і домішка `Auditable on Identifiable`. |
| `lib/src/vehicle.dart` | Другий клас, що отримує ту саму домішку. |
| `lib/src/repository.dart` | Узагальнене сховище `Repository<T extends Identifiable>`. |
| `lib/src/extensions.dart` | Методи розширення `String` і `DateTime`. |
| `lib/src/fleet_analytics.dart` | Розширення `Iterable<ServiceRecord>`, записи (`records`), зразки з `when`. |
| `lib/src/csv_parser.dart`, `loader.dart` | Розбір рядків без винятків; завантаження з переліком помилок. |
| `lib/src/sample_data.dart` | 20 вхідних рядків (4 помилки розбору, 1 дублікат, 2 порушення діапазонів). |
| `lib/src/constants.dart` | Іменовані константи (жодних «магічних» чисел у коді). |

## Обґрунтування проєктних рішень

**Незмінні об'єкти.** Усі поля `ServiceRecord` — `final`, конструктор
константний. Запис про виконане обслуговування — факт, який не змінюється;
незмінність виключає цілий клас помилок (випадкова зміна об'єкта, що лежить у
`Set` або як ключ `Map`) і дозволяє безпечно ділити екземпляри (фабрика
`cached`).

**Два способи розбору.** Очікувана помилка в даних (пошкоджений рядок) не є
винятковою ситуацією, тому основний шлях — `ServiceRecord.tryParse`, що
повертає запис `({record, error})`, без `try/catch`. Іменований конструктор
`fromCsv` не може повернути `null`, тому для нього контракт інший: некоректний
рядок — порушення передумови, і кидається `FormatException`. Обидва шляхи
використовують одну функцію `parseFields`, тож правила розбору не дублюються.

**Типи даних.** Дата — `DateTime` (а не рядок), пробіг — `int`, вартість —
`double`. Для вартості `double` достатній у межах навчального завдання; у
реальній бухгалтерії використовували б цілі копійки. Тип робіт — `enum`
`WorkType`, а не `String`: компілятор перевіряє всі вживання, а категорія
(`ServiceCategory`) зберігається як константне поле перелічення.

**Запечатана ієрархія.** `ServiceCategory` — `sealed`: список підтипів
закритий, тож `switch` у `warrantyMonths` перевіряється на вичерпність без
гілки `default`. Додавання нового підтипу спричиняє помилку компіляції у всіх
місцях, де його не опрацьовано.

**Домішка `Auditable on Identifiable`.** Поведінка (службова позначка) потрібна
класам, що не мають спільного предка, окрім `Identifiable`, і не потрібна
кожному `Identifiable`. Одиночне успадкування в Dart не дозволяє «додати
другого предка», а винесення поведінки в `Identifiable` нав'язало б її всім
нащадкам. Обмеження `on` дає доступ до `id` у домішці й забороняє
підмішувати її до сторонніх класів.

**Розподіл коду між `bin/` і `lib/`.** У `bin/` — лише сценарій демонстрації й
виведення; уся логіка — у `lib/src/` і відкрита через один файл
`lib/fleet_service.dart`, щоб її можна було використати в лабораторних роботах
3 і 4 без змін.

**`Repository<T extends Identifiable>`.** Обмеження параметра типу потрібне,
бо без нього вираз `item.id` не скомпілюється: для довільного `T`
компілятор знає лише члени `Object`. Те саме сховище обслуговує і
`ServiceRecord`, і `Vehicle`.

## Обґрунтування вживання `!`, `late`, `dynamic`

* Оператор `!` — **не вживається**. Значення, що можуть бути `null`, обробляються
  деструктуризацією запису (`final (:record, :error) = …`) і перевіркою
  `if (record == null)`, після чого відбувається промоція типу.
* Ключове слово `late` — **не вживається**. Усі поля ініціалізуються в
  конструкторі або під час оголошення.
* Тип `dynamic` — **не вживається**; увімкнено `strict-casts`,
  `strict-inference`, `strict-raw-types`.
* `// ignore: hash_and_equals` — **один раз**, у
  `lib/src/legacy/record_without_hash.dart`. Клас навмисно перевизначає `==`
  без `hashCode`, щоб показати наслідок у кроці 4 завдання. У виробничому коді
  таке порушення недопустиме.

## Залежності

Залежностей часу виконання **немає** — використано лише стандартну бібліотеку
(`dart:core`, `dart:io` у `bin/`).

Єдина залежність розробки — `lints` (набір правил `recommended.yaml`).
Обрана, бо саме цей набір вимагається п. 1.2 методичних вказівок і її
підтримує команда Dart. Розглядалися альтернативи: `flutter_lints` (зайва
прив'язка до Flutter, застосунок консольний) і `very_good_analysis` (суворіший,
але частина правил виходить за межі навчального посібника Effective Dart).

## Експерименти з завдання

* **Крок 3.** Первинний конструктор: оголошення класу, полів і конструктора
  скоротилося з 15 до 8 значущих рядків; поведінка не змінилася
  (рядкові подання й `id` збігаються — вивід кроку 3).
* **Крок 4.** Два однакові за значенням об'єкти в `Set`: з `hashCode` розмір 1,
  без `hashCode` — 2. Конструктор `RecordWithoutHash` свідомо не константний:
  два `const`-об'єкти з однаковими аргументами канонізуються в один
  екземпляр, і різниці не було б видно.
* **Крок 6.** Додавання четвертого підтипу `Recall` дає помилку
  `non_exhaustive_switch_expression`.

## Секрети

Файл `.gitignore` виключає `.dart_tool/` і `build/`; ключів API та паролів у
репозиторії немає.


---

# Лабораторна робота 3. Асинхронна та паралельна обробка даних

Лабораторна 3 доповнює модель ЛР 2 (`ServiceRecord`, `WorkType`,
`Identifiable`, `sampleLines`, `loadRecords`); код ЛР 2 не змінювався.

## Запуск

```bash
dart pub get
dart run bin/async_demo.dart   # демонстрації кроків 3–15
dart analyze                   # No issues found!
dart format --output=none --set-exit-if-changed .
dart test                      # 17 тестів
```

`bin/fleet_service.dart` (демонстрація ЛР 2) залишено без змін.

## Нові файли

| Файл | Призначення |
| --- | --- |
| `analysis_options.yaml` | `recommended` + `strict-*` + `unawaited_futures`, `discarded_futures`, `avoid_print` |
| `lib/src/async/async_repository.dart` | `AsyncRepository<T extends Identifiable>` — асинхронний аналог `Repository<T>`; `EntityNotFoundException` |
| `lib/src/async/change_event.dart`, `change_event_bus.dart` | Події змін і шина на `StreamController` |
| `lib/src/async/futures_demo.dart` | Кроки 3–6 |
| `lib/src/async/stream_demo.dart` | Кроки 7–13 |
| `lib/src/async/isolate_demo.dart` | Кроки 14–15 |
| `lib/src/async/demo_data.dart`, `console.dart` | Дані з `sampleLines`; єдиний виклик `print` |
| `bin/async_demo.dart` | Точка входу ЛР 3 |
| `test/*_test.dart` | Модульні тести |
| `docs/evidence/` | Виводи для звіту |

## Відповідність пунктам порядку виконання

| № | Що зроблено | Де |
| --- | --- | --- |
| 1 | Лінти увімкнено; на коді ЛР 2 вони нічого не знаходять (код синхронний), підсвічують лише навмисні приклади кроків 3 і 6 | `docs/evidence/lint_step1_unawaited_discarded.txt` |
| 2 | `load`, `save`, `delete` (+ `loadOrThrow`, `watchAll`) повертають `Future`/`Stream` | `AsyncRepository` |
| 3 | «Забутий await» | `demonstrateForgottenAwait` |
| 4 | 3 × 500 мс: послідовно проти `Future.wait` | `compareSequentialAndConcurrent` |
| 5 | Помилка однієї з трьох операцій: `Future.wait` проти `.wait` | `compareWaitStrategies` |
| 6 | `try/catch` без `await`, `runZonedGuarded` | `demonstrateUncaughtAsyncError` |
| 7 | `async*` і `await for` | `consumeWithAwaitFor` |
| 8 | Лінивість генератора | `demonstrateLazyGenerator` |
| 9–10 | `StreamController`, події до підписки, `listen` + `cancel` у `finally` | `ChangeEventBus`, `demonstrateBufferedEvents` |
| 11 | Помилка в потоці: `await for` проти `listen(cancelOnError: false)` | `compareErrorHandling` |
| 12 | Одноразовий і широкомовний потік | `compareSingleAndBroadcast` |
| 13 | Конвеєр `where → map → take` | `buildAddedIdsPipeline` |
| 14 | `Isolate.run`, виміри часу й «тиків» таймера | `compareMainAndIsolate`, `compareParallelIsolates` |
| 15 | Глобальна змінна в ізоляті | `demonstrateGlobalIsolation` |
| 16 | 17 тестів: `group`, `setUp`, `expectLater`; помилка й порядок подій | `test/` |
| 17 | `dart analyze`, `dart format`, `dart test` | див. «Запуск» |

## Обґрунтування рішень

**Сховище.** `AsyncRepository<T extends Identifiable>` повторює контракт
`Repository<T>` з ЛР 2 (`add` → `save`, `findById` → `load`), але кожна операція
асинхронна. Затримка джерела імітується `Future.delayed` і налаштовується:
демонстрації використовують сотні мілісекунд, тести — `Duration.zero`.
Відсутність сутності в `load` — звичайна ситуація (`null`); `loadOrThrow`
кидає `EntityNotFoundException`, коли відсутність є помилкою.

**Шина подій.** За замовчуванням `StreamController` одноразової підписки:
події до підписки буферизуються. Широкомовний режим (`broadcast: true`)
дозволяє кілька підписників, але події без підписників губляться.

**Правило підписок.** `listen()` → підписка зберігається й скасовується у
`finally`; `await for` скасовує її при виході з циклу; `first` і `take`
скасовують її самі.

**Ізолят.** Лише для справді важкого синхронного обчислення: агрегація вартості
за номерами по 20 мільйонах згенерованих записів. Генератор детермінований,
тому результат збігається з обчисленням у головному ізоляті (перевіряє тест).
Крім часу вимірюється кількість «тиків» таймера: у головному ізоляті
під час обчислення таймер стоїть, у `Isolate.run` — триває.

**Дані.** Демонстрації беруть записи з `loadRecords(sampleLines)`; перший і
шістнадцятий рядки дають однаковий `id`, тому в сховищі їх 15.

## `!`, `late`, `dynamic` та приглушення правил

`!`, `late`, `dynamic` у коді ЛР 3 **не вживаються**.

| Місце | Правило | Чому |
| --- | --- | --- |
| `async/console.dart` | `avoid_print` | Єдине місце виклику `print` |
| `demonstrateForgottenAwait` | `unawaited_futures` | Навмисна помилка (крок 3) |
| `demonstrateUncaughtAsyncError` | `discarded_futures` | Навмисна помилка (крок 6) |

## Залежності

Залежностей часу виконання немає (`dart:async`, `dart:isolate`, `dart:io`).
Нова залежність розробки — `test`: модульні тести, матчери потоків
(`emitsInOrder`, `emitsError`) і `Future` (`completion`, `throwsA`);
альтернатива — перевірки вручну через `assert`, але вона не вміє чекати на
потоки. `lints` — як у ЛР 2.

## Git

Для ЛР 3 — окрема гілка (наприклад, `lab3`) і щонайменше 5 комітів у різні
дні, напр.: (1) `analysis_options.yaml`, `test` у `pubspec`; (2) сховище й шина
подій; (3) `Future`-демонстрації, кроки 3–6; (4) `Stream`-демонстрації, кроки
7–13; (5) ізоляти й тести. Попередній стан коду не видаляється.
