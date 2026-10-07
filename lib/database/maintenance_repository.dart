import '../models/maintenance_record.dart';
import '../models/maintenance_schedule.dart';
import '../models/tire.dart';
import '../models/vehicle.dart';

abstract class MaintenanceRepository {
  bool get isCloud => false;
  String? get accountEmail => null;
  Future<List<Vehicle>> getVehicles();
  Future<int> insertVehicle(Vehicle vehicle);
  Future<void> updateVehicle(Vehicle vehicle);
  Future<void> deleteVehicle(int id);
  Future<List<MaintenanceRecord>> getMaintenanceRecords(int id);
  Future<List<MaintenanceRecord>> getAllRecords();
  Future<void> insertMaintenanceRecord(MaintenanceRecord record);
  Future<void> updateMaintenanceRecord(MaintenanceRecord record);
  Future<void> deleteMaintenanceRecord(int id);
  Future<List<MaintenanceSchedule>> getSchedules(int id);
  Future<List<MaintenanceSchedule>> getAllSchedules();
  Future<void> insertSchedule(MaintenanceSchedule schedule);
  Future<void> updateSchedule(MaintenanceSchedule schedule);
  Future<void> deleteSchedule(int id);
  Future<void> completeSchedule(int id, MaintenanceRecord? record);
  Future<List<Tire>> getAllTires();
  Future<void> saveTire(Tire tire);
  Future<void> deleteTire(int id);
  Future<Map<String, String>> getSettings();
  Future<void> setSetting(String key, String value);
  Future<void> changeUnit(String unit, String oldUnit);
  Future<void> addSampleData();
}
