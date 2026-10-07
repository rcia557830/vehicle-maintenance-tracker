class Vehicle {
  final int? id;
  final String nickname, make, model, plateNumber, unit, notes;
  final int year;
  final double odometer;
  const Vehicle({
    this.id,
    required this.nickname,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.odometer,
    this.unit = 'km',
    this.notes = '',
  });
  Map<String, Object?> toMap() => {
    'id': id,
    'nickname': nickname,
    'make': make,
    'model': model,
    'year': year,
    'plate_number': plateNumber,
    'current_odometer': odometer,
    'odometer_unit': unit,
    'notes': notes,
  };
  factory Vehicle.fromMap(Map<String, Object?> m) => Vehicle(
    id: m['id'] as int,
    nickname: m['nickname'] as String,
    make: m['make'] as String,
    model: m['model'] as String,
    year: m['year'] as int,
    plateNumber: m['plate_number'] as String,
    odometer: (m['current_odometer'] as num).toDouble(),
    unit: m['odometer_unit'] as String,
    notes: m['notes'] as String,
  );
}
