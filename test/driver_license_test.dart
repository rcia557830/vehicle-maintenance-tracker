import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/models/driver_license.dart';
import 'package:vehicle_maintenance_tracker/models/vehicle.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';

import 'ui_capture.dart';

void main() {
  test('expiry status uses calendar dates, including the expiry day', () {
    final license = DriverLicense(
      validityYears: 5,
      expiresOn: DateTime(2030, 3, 2),
    );
    expect(license.status(DateTime(2029, 12, 31)), LicenseExpiryStatus.tracked);
    expect(license.status(DateTime(2030, 1, 1)), LicenseExpiryStatus.dueSoon);
    expect(license.daysRemaining(DateTime(2030, 3, 1, 23, 59)), 1);
    expect(
      license.status(DateTime(2030, 3, 2, 23, 59)),
      LicenseExpiryStatus.expiresToday,
    );
    expect(license.status(DateTime(2030, 3, 3)), LicenseExpiryStatus.expired);
    expect(license.countdown(DateTime(2030, 3, 3)), 'Expired 1 day ago');
  });

  test('5/10-year renewal estimates preserve month/day and clamp leap day', () {
    expect(
      DriverLicense.estimateRenewal(DateTime(2026, 10, 1), 5),
      DateTime(2031, 10, 1),
    );
    expect(
      DriverLicense.estimateRenewal(DateTime(2026, 10, 1), 10),
      DateTime(2036, 10, 1),
    );
    expect(
      DriverLicense.estimateRenewal(DateTime(2024, 2, 29), 5),
      DateTime(2029, 2, 28),
    );
    expect(
      () => DriverLicense.estimateRenewal(DateTime(2026), 3),
      throwsArgumentError,
    );
  });

  test(
    'license settings round trip; malformed dates and validity are rejected',
    () {
      final saved = DriverLicense(
        validityYears: 10,
        expiresOn: DateTime(2036, 10, 1, 15),
      );
      final decoded = DriverLicense.decode(saved.encode())!;
      expect(decoded.expiresOn, DateTime(2036, 10, 1));
      expect(decoded.validityYears, 10);
      for (final value in [
        null,
        '',
        'null',
        '{}',
        'invalid',
        '{"validity_years":3,"expires_on":"2030-01-01"}',
        '{"validity_years":5,"expires_on":"2030-02-30"}',
        '{"validity_years":5,"expires_on":"2030-00-01"}',
      ]) {
        expect(DriverLicense.decode(value), isNull);
      }
    },
  );

  test('license persists without vehicles and survives switches and vehicle deletion', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final db = DatabaseHelper(databasePath: inMemoryDatabasePath);
    final p = MaintenanceProvider(db, NoPlatformNotifications());
    addTearDown(() async {
      p.dispose();
      await db.close();
    });
    await p.load();
    await p.saveDriverLicense(
      DriverLicense(validityYears: 5, expiresOn: DateTime(2030, 1, 15)),
    );
    await p.saveVehicle(
      const Vehicle(
        nickname: 'Car one',
        make: 'Toyota',
        model: 'Vios',
        year: 2023,
        plateNumber: 'ONE',
        odometer: 500,
      ),
    );
    final first = p.vehicle!.id!;
    await p.saveVehicle(
      const Vehicle(
        nickname: 'Car two',
        make: 'Honda',
        model: 'City',
        year: 2024,
        plateNumber: 'TWO',
        odometer: 100,
      ),
    );
    await p.selectVehicle(first);
    await p.deleteVehicle(first);
    await p.deleteVehicle();
    expect(p.vehicles, isEmpty);
    expect(p.driverLicense!.expiresOn, DateTime(2030, 1, 15));
    await p.saveDriverLicense(
      DriverLicense(validityYears: 10, expiresOn: DateTime(2040, 1, 15)),
    );
    final reloaded = MaintenanceProvider(db, NoPlatformNotifications());
    addTearDown(reloaded.dispose);
    await reloaded.load();
    expect(reloaded.driverLicense!.validityYears, 10);
    expect(reloaded.driverLicense!.expiresOn, DateTime(2040, 1, 15));
    await expectLater(
      p.saveDriverLicense(
        DriverLicense(validityYears: 3, expiresOn: DateTime(2030)),
      ),
      throwsArgumentError,
    );
    await p.removeDriverLicense();
    await reloaded.load();
    expect(reloaded.driverLicense, isNull);
  });
}
