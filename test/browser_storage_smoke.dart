import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/database/database_platform.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/services/notification_service.dart';
import 'package:vehicle_maintenance_tracker/models/vehicle.dart';

// Run with flutter run -d chrome -t test/browser_storage_smoke.dart.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDatabase();
  final path = 'browser_smoke_${DateTime.now().microsecondsSinceEpoch}.db';
  var db = DatabaseHelper(databasePath: path);
  MaintenanceProvider? provider;
  var result = 'Browser storage check passed';
  try {
    await db.addSampleData();
    await db.close();
    db = DatabaseHelper(databasePath: path);
    final notifications = NotificationService();
    provider = MaintenanceProvider(db, notifications);
    await provider.load();
    await provider.syncReminders();
    if (provider.error != null ||
        provider.vehicle == null ||
        provider.records.length != 3 ||
        provider.totalCost != 12500 ||
        provider.nextPms != 50000 ||
        provider.notificationWarning != null ||
        notifications.supported ||
        await notifications.requestPermission()) {
      throw StateError(
        'Persistence, startup, totals, or notification check failed',
      );
    }
    final firstId = provider.vehicle!.id!;
    await provider.saveVehicle(
      const Vehicle(
        nickname: 'Browser Test Car',
        make: 'Honda',
        model: 'City',
        year: 2024,
        plateNumber: 'TEST 002',
        odometer: 1000,
      ),
    );
    final secondId = provider.vehicle!.id!;
    await provider.load();
    if (provider.vehicle!.id != secondId ||
        provider.records.isNotEmpty ||
        provider.vehicles.length != 2) {
      throw StateError('Multiple vehicle selection or isolation failed');
    }
    await provider.selectVehicle(firstId);
    if (provider.totalCost != 12500) {
      throw StateError('Vehicle totals were not restored');
    }
    await provider.deleteVehicle(secondId);
    await provider.deleteVehicle(firstId);
    if ((await db.getVehicles()).isNotEmpty ||
        (await (await db.database).query('maintenance_records')).isNotEmpty ||
        (await (await db.database).query('maintenance_schedules')).isNotEmpty) {
      throw StateError('Cascading deletion failed');
    }
  } catch (error, stack) {
    result = 'Browser storage check FAILED: $error';
    debugPrintStack(stackTrace: stack);
  } finally {
    provider?.dispose();
    await db.close();
    await deleteDatabase(path);
  }
  debugPrint(result);
  runApp(
    MaterialApp(
      home: Scaffold(body: Center(child: Text(result))),
    ),
  );
}
