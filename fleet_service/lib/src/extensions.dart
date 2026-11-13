import 'constants.dart';

final RegExp _plateRegExp = RegExp(
  r'^(?<region>[ABCEHIKMOPTX]{2})(?<digits>\d{4})(?<series>[ABCEHIKMOPTX]{2})$',
);

/// Розширення рядка для роботи з державними номерними знаками України.
extension PlateString on String {
  /// Чи відповідає рядок формату `AA1234BB` (літери лише латиницею з
  /// дозволеного набору).
  bool get isValidPlate => _plateRegExp.hasMatch(this);

  /// Номер із прихованими цифрами: `AX1234BB` → `AX****BB`; для рядка, що
  /// не є номером, повертає його без змін.
  String get maskedPlate {
    final match = _plateRegExp.firstMatch(this);
    if (match == null) {
      return this;
    }
    return '${match.namedGroup('region')}****${match.namedGroup('series')}';
  }
}

/// Розширення дати для арифметики й форматування.
extension DateTimeX on DateTime {
  /// Дата у форматі `рррр-мм-дд`.
  String get isoDate => toIso8601String().substring(0, isoDateLength);

  /// Кількість повних діб від [other] до цієї дати.
  int daysSince(DateTime other) => difference(other).inDays;
}
