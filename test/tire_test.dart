import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/models/tire.dart';
import 'package:vehicle_maintenance_tracker/models/vehicle.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/services/notification_service.dart';

void main() {
  Tire tire({DateTime? made, int years = 6}) => Tire(
    vehicleId: 1,
    position: 'Front left',
    manufacturedOn: made ?? DateTime(2020, 10),
    replacementYears: years,
  );
  test(
    'replacement target uses manufacture month, not purchase or current year',
    () {
      expect(tire().replacementDate, DateTime(2026, 10));
      expect(tire(years: 8).replacementYear, 2028);
      expect(tire().ageMonths(DateTime(2026, 9, 30)), 71);
      expect(
        tire().status(DateTime(2026, 10, 1)),
        TireAgeStatus.replacementDue,
      );
      expect(tire().status(DateTime(2026, 9, 30)), TireAgeStatus.dueSoon);
    },
  );
  test('age flags respect five-year and six-month boundaries', () {
    expect(tire(years: 10).status(DateTime(2025, 9)), TireAgeStatus.tracking);
    expect(tire(years: 10).status(DateTime(2025, 10)), TireAgeStatus.inspect);
    expect(tire().status(DateTime(2026, 3)), TireAgeStatus.inspect);
    expect(tire().status(DateTime(2026, 4)), TireAgeStatus.dueSoon);
    expect(tire().status(DateTime(2030)), TireAgeStatus.replacementDue);
    expect(tire(made: DateTime(2020, 2)).replacementDate, DateTime(2026, 2));
  });
  test('invalid manufacture dates and replacement ages are rejected', () {
    final now = DateTime(2026, 9, 30);
    expect(tire(made: DateTime(2026, 10)).validate(now: now), isNotNull);
    expect(tire(made: DateTime(1999)).validate(now: now), isNotNull);
    expect(tire(made: DateTime(2026, 9)).validate(now: now), isNull);
    expect(tire(years: 0).validate(now: now), isNotNull);
    expect(tire(years: 11).validate(now: now), isNotNull);
  });
  test('tires persist per vehicle, update, reject duplicates and cascade on delete', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = DatabaseHelper(databasePath: inMemoryDatabasePath);
    final provider = MaintenanceProvider(db, NotificationService());
    addTearDown(() async {
      provider.dispose();
      await db.close();
    });
    await provider.load();
    await provider.saveVehicle(
      const Vehicle(
        nickname: 'One',
        make: 'Toyota',
        model: 'Vios',
        year: 2022,
        plateNumber: 'ONE',
        odometer: 100,
      ),
    );
    final first = provider.vehicle!.id!;
    await provider.saveTire(
      Tire(
        vehicleId: first,
        position: 'Front left',
        manufacturedOn: DateTime(2020, 10),
      ),
    );
    final saved = provider.tires.single;
    expect(saved.replacementYear, 2026);
    await expectLater(
      provider.saveTire(
        Tire(
          vehicleId: first,
          position: 'Front left',
          manufacturedOn: DateTime(2022),
        ),
      ),
      throwsArgumentError,
    );
    await provider.saveTire(
      Tire(
        id: saved.id,
        vehicleId: first,
        position: saved.position,
        manufacturedOn: DateTime(2022),
        replacementYears: 8,
      ),
    );
    expect(provider.tires.single.replacementYear, 2030);
    await provider.saveVehicle(
      const Vehicle(
        nickname: 'Two',
        make: 'Honda',
        model: 'City',
        year: 2022,
        plateNumber: 'TWO',
        odometer: 100,
      ),
    );
    expect(provider.tires, isEmpty);
    await expectLater(
      provider.saveTire(
        Tire(
          vehicleId: first,
          position: 'Spare',
          manufacturedOn: DateTime(2022),
        ),
      ),
      throwsStateError,
    );
    await provider.saveTire(
      Tire(
        vehicleId: provider.vehicle!.id!,
        position: 'Spare',
        manufacturedOn: DateTime(2022),
      ),
    );
    await provider.deleteTire(provider.tires.single.id!);
    expect(provider.tires, isEmpty);
    await provider.deleteVehicle(first);
    expect(await db.getAllTires(), isEmpty);
  });
  test(
    'upgrading a legacy database preserves vehicles and service records',
    () async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final file = File(
        'build/legacy_upgrade_${DateTime.now().microsecondsSinceEpoch}.db',
      ).absolute;
      await file.parent.create(recursive: true);
      final legacy = DatabaseHelper(databasePath: file.path);
      final upgraded = DatabaseHelper(databasePath: file.path);
      try {
        await legacy.addSampleData();
        final sqlite = await legacy.database;
        await sqlite.execute('DROP TABLE tires');
        await sqlite.execute('PRAGMA user_version = 1');
        await legacy.close();
        expect((await upgraded.getVehicles()).single.nickname, 'Family Car');
        expect((await upgraded.getAllRecords()).length, 3);
        expect(await upgraded.getAllTires(), isEmpty);
        expect(await (await upgraded.database).getVersion(), 2);
      } finally {
        await legacy.close();
        await upgraded.close();
        if (await file.exists()) await file.delete();
      }
    },
  );
}
