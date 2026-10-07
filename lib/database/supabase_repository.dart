import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/maintenance_record.dart';
import '../models/maintenance_schedule.dart';
import '../models/tire.dart';
import '../models/vehicle.dart';
import 'database_helper.dart';
import 'maintenance_repository.dart';

class SupabaseRepository extends MaintenanceRepository {
  SupabaseRepository(this.client) : _userId = client.auth.currentUser!.id;
  final SupabaseClient client;
  final String _userId;
  @override
  bool get isCloud => true;
  @override
  String? get accountEmail => client.auth.currentUser?.email;

  void _checkSession() {
    if (client.auth.currentUser?.id != _userId) {
      throw StateError('Your session changed. Sign in again.');
    }
  }

  // PostgREST limits each response. Page explicitly so large garages stay complete.
  Future<List<Map<String, dynamic>>> _rows(
    String table, {
    String order = 'id',
  }) async {
    _checkSession();
    final result = <Map<String, dynamic>>[];
    for (var start = 0; ; start += 500) {
      final page = await client
          .from(table)
          .select()
          .eq('user_id', _userId)
          .order(order)
          .range(start, start + 499);
      result.addAll(page);
      if (page.length < 500) return result;
    }
  }

  Map<String, Object?> _payload(Map<String, Object?> map) => {
    ...map..remove('id'),
    'user_id': _userId,
  };

  Future<int> _insert(String table, Map<String, Object?> map) async {
    _checkSession();
    final row = await client
        .from(table)
        .insert(_payload(map))
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<void> _update(String table, Map<String, Object?> map) async {
    _checkSession();
    final id = map['id'];
    await client
        .from(table)
        .update(_payload(map))
        .eq('user_id', _userId)
        .eq('id', id!)
        .select('id')
        .single();
  }

  Future<void> _delete(String table, int id) async {
    _checkSession();
    await client
        .from(table)
        .delete()
        .eq('user_id', _userId)
        .eq('id', id)
        .select('id')
        .single();
  }

  @override
  Future<List<Vehicle>> getVehicles() async =>
      (await _rows('vehicles')).map(Vehicle.fromMap).toList();
  @override
  Future<int> insertVehicle(Vehicle vehicle) =>
      _insert('vehicles', vehicle.toMap());
  @override
  Future<void> updateVehicle(Vehicle vehicle) =>
      _update('vehicles', vehicle.toMap());
  @override
  Future<void> deleteVehicle(int id) => _delete('vehicles', id);

  @override
  Future<List<MaintenanceRecord>> getAllRecords() async =>
      (await _rows('maintenance_records'))
          .map(MaintenanceRecord.fromMap)
          .toList()
        ..sort((a, b) {
          final order = b.date.compareTo(a.date);
          return order == 0 ? b.id!.compareTo(a.id!) : order;
        });
  @override
  Future<List<MaintenanceRecord>> getMaintenanceRecords(int id) async =>
      (await getAllRecords()).where((r) => r.vehicleId == id).toList();
  @override
  Future<void> insertMaintenanceRecord(MaintenanceRecord record) async {
    await _insert('maintenance_records', record.toMap());
  }

  @override
  Future<void> updateMaintenanceRecord(MaintenanceRecord record) =>
      _update('maintenance_records', record.toMap());
  @override
  Future<void> deleteMaintenanceRecord(int id) =>
      _delete('maintenance_records', id);

  @override
  Future<List<MaintenanceSchedule>> getAllSchedules() async =>
      (await _rows('maintenance_schedules'))
          .map(MaintenanceSchedule.fromMap)
          .toList()
        ..sort((a, b) {
          final order = a.date.compareTo(b.date);
          return order == 0 ? a.odometer.compareTo(b.odometer) : order;
        });
  @override
  Future<List<MaintenanceSchedule>> getSchedules(int id) async =>
      (await getAllSchedules()).where((s) => s.vehicleId == id).toList();
  @override
  Future<void> insertSchedule(MaintenanceSchedule schedule) async {
    await _insert('maintenance_schedules', schedule.toMap());
  }

  @override
  Future<void> updateSchedule(MaintenanceSchedule schedule) =>
      _update('maintenance_schedules', schedule.toMap());
  @override
  Future<void> deleteSchedule(int id) => _delete('maintenance_schedules', id);
  @override
  Future<void> completeSchedule(int id, MaintenanceRecord? record) async {
    _checkSession();
    await client.rpc(
      'complete_maintenance',
      params: {
        'schedule_id': id,
        'service_record': record == null
            ? null
            : (record.toMap()..remove('id')),
      },
    );
  }

  @override
  Future<List<Tire>> getAllTires() async =>
      (await _rows('tires')).map(Tire.fromMap).toList()
        ..sort((a, b) => a.replacementDate.compareTo(b.replacementDate));
  @override
  Future<void> saveTire(Tire tire) async {
    if (tire.id == null) {
      await _insert('tires', tire.toMap());
    } else {
      await _update('tires', tire.toMap());
    }
  }

  @override
  Future<void> deleteTire(int id) => _delete('tires', id);
  @override
  Future<Map<String, String>> getSettings() async => {
    for (final row in await _rows('settings', order: 'key'))
      row['key'] as String: row['value'] as String,
  };
  @override
  Future<void> setSetting(String key, String value) async {
    _checkSession();
    await client.from('settings').upsert({
      'user_id': _userId,
      'key': key,
      'value': value,
    }, onConflict: 'user_id,key');
  }

  @override
  Future<void> changeUnit(String unit, String oldUnit) async {
    _checkSession();
    await client.rpc('change_distance_unit', params: {'new_unit': unit});
  }

  Future<int> importLocalData() async {
    _checkSession();
    final legacy = DatabaseHelper();
    try {
      final vehicles = await legacy.getVehicles();
      if (vehicles.isEmpty) {
        throw StateError('No local vehicles found on this device.');
      }
      final settings = await legacy.getSettings();
      var importId = settings['cloud_import_id'];
      if (importId == null) {
        final random = Random.secure();
        importId = List.generate(
          24,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        await legacy.setSetting('cloud_import_id', importId);
      }
      final payload = {
        'vehicles': vehicles.map((v) => v.toMap()).toList(),
        'records': (await legacy.getAllRecords())
            .map((r) => r.toMap())
            .toList(),
        'schedules': (await legacy.getAllSchedules())
            .map((s) => s.toMap())
            .toList(),
        'tires': (await legacy.getAllTires()).map((t) => t.toMap()).toList(),
        'settings': settings,
      };
      _checkSession();
      return await client.rpc(
        'import_local_garage',
        params: {'payload': payload, 'import_id': importId},
      ) as int;
    } finally {
      await legacy.close();
    }
  }

  @override
  Future<void> addSampleData() async {
    _checkSession();
    await client.rpc(
      'import_local_garage',
      params: {
        'import_id': 'sample_${DateTime.now().microsecondsSinceEpoch}',
        'payload': {
          'vehicles': [
            const Vehicle(
              id: 1,
              nickname: 'Family Car',
              make: 'Toyota',
              model: 'Fortuner',
              year: 2021,
              plateNumber: 'DEMO 123',
              odometer: 48500,
            ).toMap(),
          ],
          'records': [
            MaintenanceRecord(
              vehicleId: 1,
              type: 'PMS',
              date: DateTime.now().subtract(const Duration(days: 60)),
              odometer: 40000,
              cost: 7500,
              shop: 'Sample service center',
            ).toMap(),
          ],
          'schedules': [
            MaintenanceSchedule(
              vehicleId: 1,
              type: 'PMS',
              date: DateTime.now().add(const Duration(days: 21)),
              odometer: 50000,
              reminder: false,
            ).toMap(),
          ],
          'tires': [],
          'settings': {'unit': 'km'},
        },
      },
    );
  }
}
