enum TireAgeStatus { tracking, inspect, dueSoon, replacementDue }

/// Calendar-age planning only; this cannot determine a tire's roadworthiness.
class Tire {
  const Tire({
    this.id,
    required this.vehicleId,
    required this.position,
    required this.manufacturedOn,
    this.brand = '',
    this.replacementYears = 6,
    this.notes = '',
  });

  static const positions = [
    'Front left',
    'Front right',
    'Rear left',
    'Rear right',
    'Spare',
  ];
  final int? id;
  final int vehicleId, replacementYears;
  final String position, brand, notes;
  // The first of the manufacture month, deliberately avoiding false day precision.
  final DateTime manufacturedOn;
  DateTime get replacementDate =>
      DateTime(manufacturedOn.year + replacementYears, manufacturedOn.month);
  int get replacementYear => replacementDate.year;
  int ageMonths(DateTime now) =>
      ((now.year - manufacturedOn.year) * 12 + now.month - manufacturedOn.month)
          .clamp(0, 1200);
  TireAgeStatus status(DateTime now) {
    final month = DateTime(now.year, now.month);
    if (!month.isBefore(replacementDate)) return TireAgeStatus.replacementDue;
    if (!DateTime(now.year, now.month + 6).isBefore(replacementDate)) {
      return TireAgeStatus.dueSoon;
    }
    if (ageMonths(now) >= 60) return TireAgeStatus.inspect;
    return TireAgeStatus.tracking;
  }

  String? validate({DateTime? now}) {
    final today = now ?? DateTime.now();
    if (!positions.contains(position)) return 'Choose a tire position.';
    if (manufacturedOn.year < 2000 ||
        manufacturedOn.isAfter(DateTime(today.year, today.month))) {
      return 'Enter a manufacture month from 2000 through this month.';
    }
    if (replacementYears < 1 || replacementYears > 10) {
      return 'Choose a replacement age from 1 to 10 years.';
    }
    return null;
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'vehicle_id': vehicleId,
    'position': position,
    'brand': brand,
    'manufactured_on':
        '${manufacturedOn.year}-${manufacturedOn.month.toString().padLeft(2, '0')}-01',
    'replacement_years': replacementYears,
    'notes': notes,
  };

  factory Tire.fromMap(Map<String, Object?> map) => Tire(
    id: map['id'] as int,
    vehicleId: map['vehicle_id'] as int,
    position: map['position'] as String,
    brand: map['brand'] as String,
    manufacturedOn: DateTime.parse(map['manufactured_on'] as String),
    replacementYears: map['replacement_years'] as int,
    notes: map['notes'] as String,
  );
}
