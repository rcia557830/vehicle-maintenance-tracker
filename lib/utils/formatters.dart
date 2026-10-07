import 'package:intl/intl.dart';

final currency = NumberFormat.currency(
  locale: 'en_PH',
  symbol: '\u20B1',
  decimalDigits: 2,
);
String money(double value) => currency.format(value);
String distance(double value, String unit) =>
    '${NumberFormat('#,##0.#').format(value)} $unit';
String dateLabel(DateTime date) => DateFormat.yMMMd().format(date);
String? requiredText(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;
String? validNumber(String? value) {
  final n = double.tryParse(value?.trim() ?? '');
  return n == null || !n.isFinite || n < 0 || n > 1000000000
      ? 'Enter a number from 0 to 1,000,000,000.'
      : null;
}
