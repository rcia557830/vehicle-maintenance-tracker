import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/models/vehicle.dart';
import 'package:vehicle_maintenance_tracker/models/driver_license.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_record.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_schedule.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/services/notification_service.dart';

class CapturedNotifications extends NotificationService {
  List<MaintenanceSchedule> pending = [];
  Map<int, String> names = {};
  @override
  Future<void> synchronize(
    List<MaintenanceSchedule> schedules,
    bool enabled, {
    Map<int, String> vehicleNames = const {},
    DriverLicense? driverLicense,
  }) async {
    pending = List.of(schedules);
    names = Map.of(vehicleNames);
  }
}

const secondVehicle = Vehicle(
  nickname: 'City Car',
  make: 'Honda',
  model: 'City',
  year: 2024,
  plateNumber: 'XYZ 5678',
  odometer: 1200,
);

void main() {
  late DatabaseHelper db;
  late MaintenanceProvider p;
  late CapturedNotifications notifications;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    db = DatabaseHelper(databasePath: inMemoryDatabasePath);
    await db.addSampleData();
    notifications = CapturedNotifications();
    p = MaintenanceProvider(db, notifications);
    await p.load();
  });
  tearDown(() async {
    p.dispose();
    await db.close();
  });

  test(
    'add, switch, remember selection, and isolate totals and PMS intervals',
    () async {
      final firstId = p.vehicle!.id!;
      await p.setInterval(8000);
      await p.saveVehicle(
        secondVehicle,
      ); // Lower mileage belongs to a different car.
      final secondId = p.vehicle!.id!;
      expect(p.vehicles.length, 2);
      expect(p.records, isEmpty);
      expect(p.schedules, isEmpty);
      expect(p.interval, 10000);
      await p.setInterval(9000);
      await p.saveRecord(
        MaintenanceRecord(
          vehicleId: secondId,
          type: 'PMS',
          date: DateTime.now(),
          odometer: 1000,
          cost: 750,
        ),
      );
      expect(p.totalCost, 750);
      expect(p.nextPms, 10000);
      final restored = MaintenanceProvider(db, notifications);
      await restored.load();
      expect(restored.vehicle!.id, secondId);
      expect(restored.interval, 9000);
      restored.dispose();
      await p.selectVehicle(firstId);
      expect(p.totalCost, 12500);
      expect(p.nextPms, 48000);
      expect(p.records.length, 3);
      expect(p.garageCost, 13250);
      await expectLater(p.updateOdometer(100), throwsArgumentError);
      await p.selectVehicle(secondId);
      await p.updateOdometer(1500);
      expect(p.vehicle!.odometer, 1500);
      expect(p.vehicles.first.odometer, 48500);
    },
  );

  test('reminders cover the garage and deleting one vehicle keeps the other intact', () async {
    final firstId = p.vehicle!.id!;
    await p.saveVehicle(secondVehicle);
    final secondId = p.vehicle!.id!;
    await p.saveSchedule(
      MaintenanceSchedule(
        vehicleId: secondId,
        type: 'Oil Change',
        date: DateTime.now().add(const Duration(days: 10)),
        odometer: 5000,
      ),
    );
    expect(notifications.pending.map((s) => s.vehicleId).toSet(), {
      firstId,
      secondId,
    });
    expect(notifications.names[secondId], contains('City Car'));
    await p.selectVehicle(firstId);
    await p.syncReminders();
    expect(notifications.pending.length, 2);
    await p.deleteVehicle(secondId);
    expect(p.vehicle!.id, firstId);
    expect(p.records.length, 3);
    expect(p.totalCost, 12500);
    expect(await db.getSchedules(secondId), isEmpty);
    expect(notifications.pending.every((s) => s.vehicleId == firstId), isTrue);
    await p.deleteVehicle();
    expect(p.vehicle, isNull);
    expect(p.records, isEmpty);
    expect(p.schedules, isEmpty);
  });

  test('deleting the selected vehicle falls back and unit conversion covers all cars', () async {
    final firstId = p.vehicle!.id!;
    await p.saveVehicle(secondVehicle);
    await p.setUnit('mi');
    expect(p.vehicle!.odometer, closeTo(1200 / 1.609344, .001));
    expect(p.vehicles.first.odometer, closeTo(48500 / 1.609344, .001));
    expect(p.allRecords.first.odometer, closeTo(48000 / 1.609344, .001));
    await p.deleteVehicle();
    expect(p.vehicle!.id, firstId);
    await p.load();
    expect(p.vehicle!.id, firstId);
    expect(p.totalCost, 12500);
  });

  test(
    'duplicate plates and cross-vehicle edits/completion are rejected',
    () async {
      final scheduleId = p.schedules.single.id!;
      final firstRecord = p.records.first;
      expect(p.plateError('abc-1234'), isNotNull);
      await expectLater(
        p.saveVehicle(
          const Vehicle(
            nickname: 'Duplicate',
            make: 'Toyota',
            model: 'Car',
            year: 2024,
            plateNumber: 'abc1234',
            odometer: 0,
          ),
        ),
        throwsArgumentError,
      );
      await p.saveVehicle(secondVehicle);
      final secondId = p.vehicle!.id!;
      await expectLater(p.deleteRecord(firstRecord.id!), throwsStateError);
      final record = MaintenanceRecord(
        vehicleId: secondId,
        type: 'PMS',
        date: DateTime.now(),
        odometer: 1000,
        cost: 100,
      );
      await expectLater(
        db.completeSchedule(scheduleId, record),
        throwsArgumentError,
      );
      expect((await db.getAllSchedules()).single.completed, isFalse);
      expect(p.records, isEmpty);
    },
  );
}
