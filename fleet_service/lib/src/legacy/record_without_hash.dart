/// Навчальний клас для експерименту: перевизначено `==`, але не `hashCode`.
///
/// Використовується лише в демонстрації кроку 4 лабораторної роботи, щоб
/// показати, чому два перевизначення мають бути парою.
class RecordWithoutHash {
  /// Створює запис із номером [plate] і пробігом [mileage].
  ///
  /// Конструктор навмисно не константний: два `const`-об'єкти з однаковими
  /// аргументами були б одним і тим самим екземпляром, і експеримент із
  /// множиною нічого б не показав.
  RecordWithoutHash(this.plate, this.mileage);

  /// Державний номерний знак.
  final String plate;

  /// Пробіг, км.
  final int mileage;

  @override
  // Свідомо порушуємо правило hash_and_equals для експерименту; див. README.md.
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is RecordWithoutHash &&
      other.plate == plate &&
      other.mileage == mileage;
}
