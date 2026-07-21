String modelDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

T enumFromApiValue<T>(
  Iterable<T> values,
  String value,
  String Function(T item) apiValue, {
  required String typeName,
}) {
  for (final item in values) {
    if (apiValue(item) == value) return item;
  }
  throw FormatException('Unknown $typeName value: $value');
}

T? nullableEnumFromApiValue<T>(
  Iterable<T> values,
  String? value,
  String Function(T item) apiValue, {
  required String typeName,
}) {
  if (value == null) return null;
  return enumFromApiValue<T>(values, value, apiValue, typeName: typeName);
}

String personName(String firstName, String lastName) {
  return '$firstName $lastName';
}
