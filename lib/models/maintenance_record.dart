class MaintenanceRecord {
  final int? id;
  final int vehicleId;
  final String type, shop, notes;
  final DateTime date;
  final double odometer, cost;
  const MaintenanceRecord({
    this.id,
    required this.vehicleId,
    required this.type,
    required this.date,
    required this.odometer,
    required this.cost,
    this.shop = '',
    this.notes = '',
  });
  Map<String, Object?> toMap() => {
    'id': id,
    'vehicle_id': vehicleId,
    'maintenance_type': type,
    'service_date': date.toIso8601String(),
    'odometer': odometer,
    'cost': cost,
    'service_provider': shop,
    'notes': notes,
  };
  factory MaintenanceRecord.fromMap(Map<String, Object?> m) =>
      MaintenanceRecord(
        id: m['id'] as int,
        vehicleId: m['vehicle_id'] as int,
        type: m['maintenance_type'] as String,
        date: DateTime.parse(m['service_date'] as String),
        odometer: (m['odometer'] as num).toDouble(),
        cost: (m['cost'] as num).toDouble(),
        shop: m['service_provider'] as String,
        notes: m['notes'] as String,
      );
}
