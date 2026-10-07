import 'package:flutter/foundation.dart';

import '../database/maintenance_repository.dart';
import '../models/driver_license.dart';
import '../models/tire.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/maintenance_schedule.dart';
import '../services/notification_service.dart';

// A garage-wide snapshot keeps selection and each vehicle's records consistent.
class MaintenanceProvider extends ChangeNotifier {
  MaintenanceProvider(this.db, this.notifications);
  final MaintenanceRepository db;
  final NotificationService notifications;
  List<Vehicle> vehicles = [];
  List<MaintenanceRecord> allRecords = [];
  List<MaintenanceSchedule> allSchedules = [];
  List<Tire> allTires = [];
  List<Tire> get tires =>
      allTires.where((t) => t.vehicleId == _selectedId).toList();
  int? _selectedId;
  Map<String, String> _settings = {};
  DriverLicense? get driverLicense =>
      DriverLicense.decode(_settings[DriverLicense.settingKey]);
  int _loadVersion = 0;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    super.dispose();
  }

  bool loading = true, switching = false;
  String? error, notificationWarning;
  String unit = 'km';
  bool remindersEnabled = false;
  Vehicle? get vehicle =>
      vehicles.where((v) => v.id == _selectedId).firstOrNull;
  List<MaintenanceRecord> get records =>
      allRecords.where((r) => r.vehicleId == _selectedId).toList();
  List<MaintenanceSchedule> get schedules =>
      allSchedules.where((s) => s.vehicleId == _selectedId).toList();
  int get interval =>
      int.tryParse(
        _settings['interval_$_selectedId'] ?? _settings['interval'] ?? '',
      ) ??
      10000;
  double get totalCost => records.fold(0, (sum, r) => sum + r.cost);
  double get garageCost => allRecords.fold(0, (sum, r) => sum + r.cost);
  double costFor(int id) => allRecords
      .where((r) => r.vehicleId == id)
      .fold(0, (sum, r) => sum + r.cost);
  List<MaintenanceSchedule> get upcoming =>
      schedules.where((s) => !s.completed).toList();
  int attentionFor(Vehicle v) => allSchedules
      .where(
        (s) =>
            s.vehicleId == v.id &&
            [
              ServiceStatus.overdue,
              ServiceStatus.dueSoon,
            ].contains(s.status(v.odometer, unit: v.unit)),
      )
      .length;
  int get overdueCount => upcoming
      .where(
        (s) => s.status(vehicle!.odometer, unit: unit) == ServiceStatus.overdue,
      )
      .length;
  MaintenanceRecord? get lastPms =>
      records.where((r) => r.type == 'PMS').firstOrNull;
  double? get nextPms => lastPms == null ? null : lastPms!.odometer + interval;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_loadVersion;
    try {
      final savedVehicles = await db.getVehicles();
      final settings = await db.getSettings();
      final savedRecords = await db.getAllRecords();
      final savedSchedules = await db.getAllSchedules();
      final savedTires = await db.getAllTires();
      if (version != _loadVersion) return;
      final preferredId = int.tryParse(settings['selected_vehicle'] ?? '');
      vehicles = savedVehicles;
      _selectedId = vehicles.any((v) => v.id == preferredId)
          ? preferredId
          : vehicles.firstOrNull?.id;
      _settings = settings;
      allRecords = savedRecords;
      allSchedules = savedSchedules;
      allTires = savedTires;
      unit = vehicle?.unit ?? settings['unit'] ?? 'km';
      remindersEnabled = settings['notifications'] == 'true';
      error = null;
    } catch (_) {
      if (version != _loadVersion) return;
      error = db.isCloud
          ? 'Unable to load your cloud garage. Check your connection and Supabase setup, then try again.'
          : 'Unable to open your saved data. Please try again.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> selectVehicle(int id) async {
    if (_disposed) return;
    if (switching || id == _selectedId) return;
    if (!vehicles.any((v) => v.id == id)) {
      throw StateError('Vehicle no longer exists.');
    }
    switching = true;
    notifyListeners();
    try {
      await db.setSetting('selected_vehicle', '$id');
      await load();
    } finally {
      switching = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> syncReminders() async {
    if (_disposed || error != null) return;
    try {
      // Always reconcile the whole garage; switching cars must not cancel reminders.
      await notifications.synchronize(
        allSchedules,
        remindersEnabled,
        driverLicense: driverLicense,
        vehicleNames: {
          for (final v in vehicles) v.id!: '${v.nickname} (${v.plateNumber})',
        },
      );
      notificationWarning = null;
    } catch (_) {
      notificationWarning = 'Your data is saved, but reminders are unavailable. Check notification settings and try again.';
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> _save(Future<void> Function() action) async {
    await action();
    await refresh();
  }

  Future<void> refresh() async {
    await load();
    await syncReminders();
  }

  String? plateError(String plate, {int? exceptId}) {
    final normalized = plate.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    return vehicles.any(
          (v) =>
              v.id != exceptId &&
              v.plateNumber.replaceAll(RegExp(r'[\s-]'), '').toUpperCase() ==
                  normalized,
        )
        ? 'This plate number is already in your garage.'
        : null;
  }

  Future<void> saveVehicle(Vehicle v) => _save(() async {
    final existing = vehicles.where((saved) => saved.id == v.id).firstOrNull;
    if (v.id != null && existing == null) {
      throw StateError('Vehicle no longer exists.');
    }
    if (existing != null && v.odometer < existing.odometer) {
      throw ArgumentError('The odometer cannot decrease.');
    }
    final duplicate = plateError(v.plateNumber, exceptId: v.id);
    if (duplicate != null) throw ArgumentError(duplicate);
    if (v.unit != unit) throw ArgumentError('Use the garage distance unit.');
    if (v.id == null) {
      final id = await db.insertVehicle(v);
      await db.setSetting('selected_vehicle', '$id');
    } else {
      await db.updateVehicle(v);
    }
  });
  Future<void> deleteVehicle([int? id]) =>
      _save(() => db.deleteVehicle(id ?? vehicle!.id!));
  Future<void> updateOdometer(double value, {int? vehicleId}) {
    final v = vehicles.firstWhere((v) => v.id == (vehicleId ?? vehicle?.id));
    return saveVehicle(
      Vehicle(
        id: v.id,
        nickname: v.nickname,
        make: v.make,
        model: v.model,
        year: v.year,
        plateNumber: v.plateNumber,
        odometer: value,
        unit: v.unit,
        notes: v.notes,
      ),
    );
  }

  void _checkVehicle(int id) {
    if (id != vehicle?.id) {
      throw StateError('Select the vehicle for this record first.');
    }
  }

  Future<void> saveRecord(MaintenanceRecord r) => _save(() async {
    _checkVehicle(r.vehicleId);
    if (r.id != null && !records.any((saved) => saved.id == r.id)) {
      throw StateError('Record no longer exists.');
    }
    if (r.id == null) {
      await db.insertMaintenanceRecord(r);
    } else {
      await db.updateMaintenanceRecord(r);
    }
  });
  Future<void> deleteRecord(int id) => _save(() async {
    if (!records.any((r) => r.id == id)) {
      throw StateError('Record no longer exists.');
    }
    await db.deleteMaintenanceRecord(id);
  });
  Future<void> saveSchedule(MaintenanceSchedule s) => _save(() async {
    _checkVehicle(s.vehicleId);
    if (s.id != null && !schedules.any((saved) => saved.id == s.id)) {
      throw StateError('Schedule no longer exists.');
    }
    if (s.id == null) {
      await db.insertSchedule(s);
    } else {
      await db.updateSchedule(s);
    }
  });
  Future<void> deleteSchedule(int id) => _save(() async {
    if (!schedules.any((s) => s.id == id)) {
      throw StateError('Schedule no longer exists.');
    }
    await db.deleteSchedule(id);
  });
  Future<void> completeSchedule(int id, MaintenanceRecord? record) =>
      _save(() async {
        if (!schedules.any((s) => s.id == id)) {
          throw StateError('Schedule no longer exists.');
        }
        if (record != null) _checkVehicle(record.vehicleId);
        await db.completeSchedule(id, record);
      });
  Future<void> setInterval(int value) => _save(
    () => db.setSetting(
      vehicle == null ? 'interval' : 'interval_$_selectedId',
      '$value',
    ),
  );
  Future<void> setUnit(String value) => _save(() => db.changeUnit(value, unit));
  Future<void> setNotifications(bool value) async {
    if (value) {
      try {
        if (!await notifications.requestPermission()) {
          notificationWarning = 'Notifications are not allowed. You can enable them in Android app settings.';
          notifyListeners();
          return;
        }
      } catch (_) {
        notificationWarning = 'Notifications are unavailable on this device.';
        notifyListeners();
        return;
      }
    }
    await _save(() => db.setSetting('notifications', '$value'));
  }

  Future<void> addSampleData() => _save(db.addSampleData);

  Future<void> saveDriverLicense(DriverLicense license) => _save(() async {
    final message = license.validate();
    if (message != null) throw ArgumentError(message);
    await db.setSetting(DriverLicense.settingKey, license.encode());
  });

  Future<void> removeDriverLicense() =>
      _save(() => db.setSetting(DriverLicense.settingKey, ''));

  Future<void> saveTire(Tire tire) => _save(() async {
    _checkVehicle(tire.vehicleId);
    final message = tire.validate();
    if (message != null) throw ArgumentError(message);
    if (tire.id != null && !tires.any((t) => t.id == tire.id)) {
      throw StateError('Tire no longer exists.');
    }
    if (tires.any((t) => t.id != tire.id && t.position == tire.position)) {
      throw ArgumentError(
        'A tire is already saved in this position. Edit it to record a replacement.',
      );
    }
    await db.saveTire(tire);
  });

  Future<void> deleteTire(int id) => _save(() async {
    if (!tires.any((t) => t.id == id)) {
      throw StateError('Tire no longer exists.');
    }
    await db.deleteTire(id);
  });
}
