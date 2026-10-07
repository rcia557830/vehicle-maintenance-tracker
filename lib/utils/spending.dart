import '../models/maintenance_record.dart';

// Calendar-month buckets also handle year boundaries and months with no records.
List<({DateTime month, double total})> monthlySpending(
  List<MaintenanceRecord> records, {
  required DateTime now,
  int months = 6,
}) => [
  for (var offset = months - 1; offset >= 0; offset--)
    (
      month: DateTime(now.year, now.month - offset),
      total: records
          .where(
            (r) =>
                r.date.year == DateTime(now.year, now.month - offset).year &&
                r.date.month == DateTime(now.year, now.month - offset).month,
          )
          .fold<double>(0, (sum, r) => sum + r.cost),
    ),
];
