import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/maintenance_provider.dart';
import '../screens/add_vehicle_screen.dart';
import 'common.dart';

class VehicleSwitcher extends StatelessWidget {
  const VehicleSwitcher({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    if (p.vehicle == null) return const SizedBox.shrink();
    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffdce6e3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    color: Color(0xff16756a),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        key: const ValueKey('vehicle-switcher'),
                        value: p.vehicle!.id,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(16),
                        hint: const Text('Select vehicle'),
                        items: p.vehicles
                            .map(
                              (v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(
                                  '${v.nickname} \u00b7 ${v.plateNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: p.switching
                            ? null
                            : (id) {
                                if (id != null) {
                                  runAction(context, () => p.selectVehicle(id));
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Add another vehicle',
            onPressed: () => openScreen(context, const AddVehicleScreen()),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
