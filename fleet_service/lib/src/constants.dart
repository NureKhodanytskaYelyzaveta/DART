/// Роздільник полів у рядку CSV-подібного формату.
const String csvSeparator = ';';

/// Кількість полів у коректному рядку: держномер, тип робіт, пробіг, дата,
/// вартість, виконавець.
const int csvFieldCount = 6;

/// Максимально припустимий пробіг автомобіля, км.
const int maxMileageKm = 1500000;

/// Максимально припустима вартість одного запису, грн.
const double maxCostUah = 1000000;

/// Пробіг, починаючи з якого автомобіль вважається «високопробіжним», км.
const int highMileageKm = 300000;

/// Вартість, починаючи з якої робота вважається дорогою, грн.
const double expensiveJobUah = 15000;

/// Вартість, починаючи з якої робота вважається середньою за ціною, грн.
const double mediumJobUah = 3000;

/// Інтервал між технічними оглядами, км.
const int inspectionIntervalKm = 30000;

/// Гарантія на планове обслуговування, місяців.
const int routineWarrantyMonths = 3;

/// Гарантія на простий ремонт, місяців.
const int simpleRepairWarrantyMonths = 6;

/// Гарантія на складний ремонт, місяців.
const int complexRepairWarrantyMonths = 12;

/// Кількість символів у даті формату `рррр-мм-дд`.
const int isoDateLength = 10;
