import 'package:flutter/material.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'workspace.dart';
import 'feedback.dart';

/// Presentational only: selection, editing, and totals stay in the screen/provider.
class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.selected,
    required this.spent,
    required this.attentionCount,
    required this.overdueCount,
    required this.onEdit,
    required this.onSelect,
  });
  final Vehicle vehicle;
  final bool selected;
  final double spent;
  final int attentionCount, overdueCount;
  final VoidCallback onEdit;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) => Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.directions_car_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: selected
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: StatusBadge(
                          label: 'Selected',
                          color: AppColors.primary,
                          icon: Icons.check_circle_outline,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                tooltip: 'Edit ${vehicle.nickname}',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(vehicle.nickname, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${vehicle.year} ${vehicle.make} ${vehicle.model}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Text(
            vehicle.plateNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _VehicleFigure(
                'Odometer',
                distance(vehicle.odometer, vehicle.unit),
              ),
              _VehicleFigure('Service spending', money(spent)),
            ],
          ),
          const SizedBox(height: 16),
          StatusBadge(
            label: overdueCount > 0
                ? '$overdueCount overdue ${overdueCount == 1 ? 'service' : 'services'}'
                : attentionCount > 0
                ? '$attentionCount services need attention'
                : 'No services due soon',
            color: overdueCount > 0
                ? AppColors.danger
                : attentionCount > 0
                ? AppColors.warning
                : AppColors.success,
            icon: attentionCount > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: ValueKey('select-vehicle-${vehicle.id}'),
              onPressed: onSelect,
              icon: Icon(selected ? Icons.check : Icons.swap_horiz),
              label: Text(selected ? 'Currently selected' : 'Select vehicle'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _VehicleFigure extends StatelessWidget {
  const _VehicleFigure(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}
