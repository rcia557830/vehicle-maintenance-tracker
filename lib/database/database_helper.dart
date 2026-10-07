import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_schedule.dart';
import '../models/tire.dart';
import 'maintenance_repository.dart';

// Retained for the one-time import of existing installations and local tests.
class DatabaseHelper extends MaintenanceRepository {
  DatabaseHelper({this.databasePath});
  final String? databasePath;
  Database? _database;
  Future<Database> get database async => _database ??= await openDatabase(
    databasePath ??
        (kIsWeb
            ? 'vehicle_maintenance.db'
            : join(await getDatabasesPath(), 'vehicle_maintenance.db')),
    version: 2,
    onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) await _createTires(db);
    },
    onCreate: (db, version) async {
      await db.execute(
        "CREATE TABLE vehicles (id INTEGER PRIMARY KEY AUTOINCREMENT, nickname TEXT NOT NULL, make TEXT NOT NULL, model TEXT NOT NULL, year INTEGER NOT NULL, plate_number TEXT NOT NULL, current_odometer REAL NOT NULL CHECK(current_odometer >= 0), odometer_unit TEXT NOT NULL, notes TEXT NOT NULL)",
      );
      await db.execute(
        "CREATE TABLE maintenance_records (id INTEGER PRIMARY KEY AUTOINCREMENT, vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE, maintenance_type TEXT NOT NULL, service_date TEXT NOT NULL, odometer REAL NOT NULL CHECK(odometer >= 0), cost REAL NOT NULL CHECK(cost >= 0), service_provider TEXT NOT NULL, notes TEXT NOT NULL)",
      );
      await db.execute(
        "CREATE TABLE maintenance_schedules (id INTEGER PRIMARY KEY AUTOINCREMENT, vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE, maintenance_type TEXT NOT NULL, due_date TEXT NOT NULL, due_odometer REAL NOT NULL CHECK(due_odometer >= 0), notes TEXT NOT NULL, reminder_enabled INTEGER NOT NULL, status TEXT NOT NULL)",
      );
      await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE INDEX records_vehicle ON maintenance_records(vehicle_id, service_date)',
      );
      await db.execute(
        'CREATE INDEX schedules_vehicle ON maintenance_schedules(vehicle_id, due_date)',
      );
      await _createTires(db);
    },
  );
  static Future<void> _createTires(Database db) => db.execute(
    'CREATE TABLE tires (id INTEGER PRIMARY KEY AUTOINCREMENT, vehicle_id INTEGER NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE, position TEXT NOT NULL, brand TEXT NOT NULL, manufactured_on TEXT NOT NULL, replacement_years INTEGER NOT NULL CHECK(replacement_years BETWEEN 1 AND 10), notes TEXT NOT NULL, UNIQUE(vehicle_id, position))',
  );

  @override
  Future<List<Tire>> getAllTires() async => (await (await database).query(
    'tires',
    orderBy: 'manufactured_on',
  )).map(Tire.fromMap).toList();

  @override
  Future<void> saveTire(Tire tire) async {
    if (tire.id == null) {
      await (await database).insert('tires', tire.toMap()..remove('id'));
    } else {
      await (await database).update(
        'tires',
        tire.toMap(),
        where: 'id = ?',
        whereArgs: [tire.id],
      );
    }
  }

  @override
  Future<void> deleteTire(int id) async {
    await (await database).delete('tires', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Vehicle>> getVehicles() async => (await (await database).query(
    'vehicles',
    orderBy: 'id',
  )).map(Vehicle.fromMap).toList();
  @override
  Future<int> insertVehicle(Vehicle v) async =>
      (await database).insert('vehicles', v.toMap()..remove('id'));
  @override
  Future<void> updateVehicle(Vehicle v) async {
    await (await database).update(
      'vehicles',
      v.toMap(),
      where: 'id = ?',
      whereArgs: [v.id],
    );
  }

  @override
  Future<void> deleteVehicle(int id) async {
    await (await database).delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<MaintenanceRecord>> getMaintenanceRecords(int id) async =>
      (await (await database).query(
        'maintenance_records',
        where: 'vehicle_id = ?',
        whereArgs: [id],
        orderBy: 'service_date DESC, id DESC',
      )).map(MaintenanceRecord.fromMap).toList();
  @override
  Future<List<MaintenanceRecord>> getAllRecords() async =>
      (await (await database).query(
        'maintenance_records',
        orderBy: 'service_date DESC, id DESC',
      )).map(MaintenanceRecord.fromMap).toList();
  @override
  Future<List<MaintenanceSchedule>> getAllSchedules() async =>
      (await (await database).query(
        'maintenance_schedules',
        orderBy: 'due_date, due_odometer',
      )).map(MaintenanceSchedule.fromMap).toList();
  @override
  Future<void> insertMaintenanceRecord(MaintenanceRecord r) async {
    await (await database).insert(
      'maintenance_records',
      r.toMap()..remove('id'),
    );
  }

  @override
  Future<void> updateMaintenanceRecord(MaintenanceRecord r) async {
    await (await database).update(
      'maintenance_records',
      r.toMap(),
      where: 'id = ?',
      whereArgs: [r.id],
    );
  }

  @override
  Future<void> deleteMaintenanceRecord(int id) async {
    await (await database).delete(
      'maintenance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<MaintenanceSchedule>> getSchedules(int id) async =>
      (await (await database).query(
        'maintenance_schedules',
        where: 'vehicle_id = ?',
        whereArgs: [id],
        orderBy: 'due_date, due_odometer',
      )).map(MaintenanceSchedule.fromMap).toList();
  @override
  Future<void> insertSchedule(MaintenanceSchedule s) async {
    await (await database).insert(
      'maintenance_schedules',
      s.toMap()..remove('id'),
    );
  }

  @override
  Future<void> updateSchedule(MaintenanceSchedule s) async {
    await (await database).update(
      'maintenance_schedules',
      s.toMap(),
      where: 'id = ?',
      whereArgs: [s.id],
    );
  }

  @override
  Future<void> deleteSchedule(int id) async {
    await (await database).delete(
      'maintenance_schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> completeSchedule(int id, MaintenanceRecord? record) async {
    await (await database).transaction((txn) async {
      final rows = await txn.query(
        'maintenance_schedules',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rows.isEmpty) throw StateError('Schedule no longer exists.');
      if (record != null && record.vehicleId != rows.single['vehicle_id']) {
        throw ArgumentError(
          'The service record must belong to the scheduled vehicle.',
        );
      }
      final changed = await txn.update(
        'maintenance_schedules',
        {'status': 'completed'},
        where: "id = ? AND status != 'completed'",
        whereArgs: [id],
      );
      if (changed == 1 && record != null) {
        await txn.insert('maintenance_records', record.toMap()..remove('id'));
      }
    });
  }

  @override
  Future<Map<String, String>> getSettings() async => {
    for (final m in await (await database).query('settings'))
      m['key'] as String: m['value'] as String,
  };
  @override
  Future<void> setSetting(String key, String value) async {
    await (await database).insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Convert every stored distance together so changing units never relabels old numbers.
  @override
  Future<void> changeUnit(String unit, String oldUnit) async {
    final factor = unit == oldUnit
        ? 1.0
        : unit == 'mi'
        ? 1 / 1.609344
        : 1.609344;
    await (await database).transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE vehicles SET current_odometer = current_odometer * ?, odometer_unit = ?',
        [factor, unit],
      );
      await txn.rawUpdate(
        'UPDATE maintenance_records SET odometer = odometer * ?',
        [factor],
      );
      await txn.rawUpdate(
        'UPDATE maintenance_schedules SET due_odometer = due_odometer * ?',
        [factor],
      );
      await txn.insert('settings', {
        'key': 'unit',
        'value': unit,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> addSampleData() async {
    await (await database).transaction((txn) async {
      if (Sqflite.firstIntValue(
            await txn.rawQuery('SELECT COUNT(*) FROM vehicles'),
          )! >
          0) {
        return;
      }
      final id = await txn.insert(
        'vehicles',
        const Vehicle(
          nickname: 'Family Car',
          make: 'Toyota',
          model: 'Fortuner',
          year: 2021,
          plateNumber: 'ABC 1234',
          odometer: 48500,
        ).toMap()..remove('id'),
      );
      for (final r in [
        MaintenanceRecord(
          vehicleId: id,
          type: 'Oil Change',
          date: DateTime(2026, 9, 15),
          odometer: 48000,
          cost: 3500,
          shop: 'ABC Auto Service',
        ),
        MaintenanceRecord(
          vehicleId: id,
          type: 'Brake Service',
          date: DateTime(2026, 8, 10),
          odometer: 45500,
          cost: 1500,
          notes: 'Brake cleaning',
        ),
        MaintenanceRecord(
          vehicleId: id,
          type: 'PMS',
          date: DateTime(2026, 5, 20),
          odometer: 40000,
          cost: 7500,
        ),
      ]) {
        await txn.insert('maintenance_records', r.toMap()..remove('id'));
      }
      await txn.insert(
        'maintenance_schedules',
        MaintenanceSchedule(
          vehicleId: id,
          type: 'PMS',
          date: DateTime.now().add(const Duration(days: 21)),
          odometer: 50000,
          reminder: false,
        ).toMap()..remove('id'),
      );
      await txn.insert('settings', {
        'key': 'unit',
        'value': 'km',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
