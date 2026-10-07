enum ServiceStatus { upcoming, dueSoon, overdue, completed }

class MaintenanceSchedule {
  final int? id;
  final int vehicleId;
  final String type, notes;
  final DateTime date;
  final double odometer;
  final bool reminder, completed;
  const MaintenanceSchedule({
    this.id,
    required this.vehicleId,
    required this.type,
    required this.date,
    required this.odometer,
    this.notes = '',
    this.reminder = true,
    this.completed = false,
  });
  ServiceStatus status(double current, {DateTime? now, String unit = 'km'}) {
    if (completed) return ServiceStatus.completed;
    final today = now ?? DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (current >= odometer || !date.isAfter(day)) return ServiceStatus.overdue;
    if (odometer - current <= (unit == 'mi' ? 621.371 : 1000) ||
        date.difference(day).inDays <= 7) {
      return ServiceStatus.dueSoon;
    }
    return ServiceStatus.upcoming;
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'vehicle_id': vehicleId,
    'maintenance_type': type,
    'due_date': date.toIso8601String(),
    'due_odometer': odometer,
    'notes': notes,
    'reminder_enabled': reminder ? 1 : 0,
    'status': completed ? 'completed' : 'upcoming',
  };
  factory MaintenanceSchedule.fromMap(Map<String, Object?> m) =>
      MaintenanceSchedule(
        id: m['id'] as int,
        vehicleId: m['vehicle_id'] as int,
        type: m['maintenance_type'] as String,
        date: DateTime.parse(m['due_date'] as String),
        odometer: (m['due_odometer'] as num).toDouble(),
        notes: m['notes'] as String,
        reminder: m['reminder_enabled'] == 1,
        completed: m['status'] == 'completed',
      );
}
