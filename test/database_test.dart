import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/models/vehicle.dart';
import 'package:vehicle_maintenance_tracker/models/driver_license.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_record.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_schedule.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/services/notification_service.dart';
import 'package:vehicle_maintenance_tracker/utils/formatters.dart';

class SilentNotifications extends NotificationService {
  @override
  Future<void> synchronize(
    List<MaintenanceSchedule> schedules,
    bool enabled, {
    Map<int, String> vehicleNames = const {},
    DriverLicense? driverLicense,
  }) async {}
}

void main() {
  late DatabaseHelper db;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() {
    db = DatabaseHelper(databasePath: inMemoryDatabasePath);
  });
  tearDown(() => db.close());
  test('sample data is idempotent, totals and PMS use saved records', () async {
    await db.addSampleData();
    await db.addSampleData();
    final p = MaintenanceProvider(db, SilentNotifications());
    await p.load();
    expect((await db.getVehicles()).length, 1);
    expect(p.records.length, 3);
    expect(p.totalCost, 12500);
    expect(p.nextPms, 50000);
    await p.setInterval(8000);
    expect(p.nextPms, 48000);
    await expectLater(p.updateOdometer(48000), throwsArgumentError);
    await p.updateOdometer(49000);
    expect(p.vehicle!.odometer, 49000);
    p.dispose();
  });
  test(
    'CRUD, atomic completion, unit conversion and cascading deletion',
    () async {
      final id = await db.insertVehicle(
        const Vehicle(
          nickname: 'Car',
          make: 'Toyota',
          model: 'Fortuner',
          year: 2021,
          plateNumber: 'ABC',
          odometer: 48500,
        ),
      );
      final record = MaintenanceRecord(
        vehicleId: id,
        type: 'Oil Change',
        date: DateTime(2026, 9, 15),
        odometer: 48000,
        cost: 3500,
      );
      await db.insertMaintenanceRecord(record);
      final saved = (await db.getMaintenanceRecords(id)).single;
      await db.updateMaintenanceRecord(
        MaintenanceRecord(
          id: saved.id,
          vehicleId: id,
          type: 'Oil Change',
          date: saved.date,
          odometer: 48000,
          cost: 4000,
          notes: 'Updated',
        ),
      );
      expect((await db.getMaintenanceRecords(id)).single.cost, 4000);
      await db.insertSchedule(
        MaintenanceSchedule(
          vehicleId: id,
          type: 'PMS',
          date: DateTime(2026, 10, 20),
          odometer: 50000,
        ),
      );
      final schedule = (await db.getSchedules(id)).single;
      await db.updateSchedule(
        MaintenanceSchedule(
          id: schedule.id,
          vehicleId: id,
          type: 'PMS',
          date: schedule.date,
          odometer: 51000,
          notes: 'Updated',
        ),
      );
      expect((await db.getSchedules(id)).single.odometer, 51000);
      await db.completeSchedule(schedule.id!, record);
      await db.completeSchedule(schedule.id!, record);
      expect((await db.getMaintenanceRecords(id)).length, 2);
      expect((await db.getSchedules(id)).single.completed, isTrue);
      await db.changeUnit('mi', 'km');
      expect(
        (await db.getVehicles()).single.odometer,
        closeTo(48500 / 1.609344, .001),
      );
      expect(
        (await db.getMaintenanceRecords(id)).first.odometer,
        closeTo(48000 / 1.609344, .001),
      );
      expect(
        (await db.getSchedules(id)).single.odometer,
        closeTo(51000 / 1.609344, .001),
      );
      await db.changeUnit('km', 'mi');
      expect((await db.getVehicles()).single.odometer, closeTo(48500, .001));
      await db.deleteMaintenanceRecord(saved.id!);
      expect((await db.getMaintenanceRecords(id)).length, 1);
      await db.deleteSchedule(schedule.id!);
      expect(await db.getSchedules(id), isEmpty);
      await db.insertSchedule(
        MaintenanceSchedule(
          vehicleId: id,
          type: 'PMS',
          date: DateTime(2026, 10, 20),
          odometer: 50000,
        ),
      );
      await db.deleteVehicle(id);
      expect(await db.getVehicles(), isEmpty);
      expect(await db.getMaintenanceRecords(id), isEmpty);
      expect(await db.getSchedules(id), isEmpty);
    },
  );
  test('foreign keys reject records without a vehicle', () async {
    await expectLater(
      db.insertMaintenanceRecord(
        MaintenanceRecord(
          vehicleId: 999,
          type: 'PMS',
          date: DateTime.now(),
          odometer: 0,
          cost: 0,
        ),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });
  test('status handles date, mileage and completion boundaries', () {
    final now = DateTime(2026, 9, 29);
    MaintenanceSchedule schedule(
      DateTime due,
      double odo, {
      bool done = false,
    }) => MaintenanceSchedule(
      vehicleId: 1,
      type: 'PMS',
      date: due,
      odometer: odo,
      completed: done,
    );
    expect(
      schedule(DateTime(2026, 10, 20), 50000).status(48500, now: now),
      ServiceStatus.upcoming,
    );
    expect(
      schedule(DateTime(2026, 10, 20), 50000).status(49000, now: now),
      ServiceStatus.dueSoon,
    );
    expect(
      schedule(DateTime(2026, 10, 20), 50000).status(50000, now: now),
      ServiceStatus.overdue,
    );
    expect(
      schedule(DateTime(2026, 10, 6), 50000).status(0, now: now),
      ServiceStatus.dueSoon,
    );
    expect(schedule(now, 50000).status(0, now: now), ServiceStatus.overdue);
    expect(
      schedule(now, 50000, done: true).status(60000, now: now),
      ServiceStatus.completed,
    );
  });
  test(
    'number validation rejects negative, nonfinite and malformed values',
    () {
      for (final value in ['', 'abc', '-1', 'NaN', 'Infinity', '1000000001']) {
        expect(validNumber(value), isNotNull);
      }
      expect(validNumber('0'), isNull);
      expect(validNumber('3500.50'), isNull);
    },
  );
}
