import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_record.dart';
import 'package:vehicle_maintenance_tracker/utils/spending.dart';

void main() {
  MaintenanceRecord record(DateTime date, double cost) => MaintenanceRecord(
    vehicleId: 1,
    type: 'PMS',
    date: date,
    cost: cost,
    odometer: 1000,
  );
  test('spending chart groups calendar months across years and excludes outside dates', () {
    final result = monthlySpending([
      record(DateTime(2025, 7, 31), 999),
      record(DateTime(2025, 8, 1), 100),
      record(DateTime(2025, 12, 1), 200),
      record(DateTime(2025, 12, 31), 300),
      record(DateTime(2026, 1, 5), 900),
      record(DateTime(2026, 2, 1), 999),
    ], now: DateTime(2026, 1, 20));
    expect(result.map((r) => r.month.month), [8, 9, 10, 11, 12, 1]);
    expect(result.first.month.year, 2025);
    expect(result.last.month.year, 2026);
    expect(result.map((r) => r.total), [100, 0, 0, 0, 500, 900]);
  });
  test('an empty history has six zero months', () {
    final result = monthlySpending([], now: DateTime(2026, 9, 30));
    expect(result.length, 6);
    expect(result.every((r) => r.total == 0), isTrue);
    expect(result.last.month, DateTime(2026, 9));
  });
}
