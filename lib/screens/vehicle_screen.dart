import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/maintenance_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';
import 'add_vehicle_screen.dart';
import 'tires_screen.dart';
import '../theme/app_theme.dart';

class VehicleScreen extends StatelessWidget {
  const VehicleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final selected = p.vehicle;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          'My garage',
          subtitle:
              '${p.vehicles.length} ${p.vehicles.length == 1 ? 'vehicle' : 'vehicles'}, one place to keep them running.',
          actions: [
            if (selected != null)
              OutlinedButton.icon(
                onPressed: () =>
                    openScreen(context, const TiresScreen(standalone: true)),
                icon: const Icon(Icons.tire_repair, size: 18),
                label: const Text('Tire care'),
              ),
            IconButton.filled(
              tooltip: 'Add vehicle',
              onPressed: () => openScreen(context, const AddVehicleScreen()),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (selected == null)
          EmptyState(
            icon: Icons.garage_outlined,
            title: 'Your garage starts here',
            message: 'Add a car or motorcycle to organize its maintenance and running costs.',
            label: 'Add vehicle',
            action: () => openScreen(context, const AddVehicleScreen()),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.sidebar,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Color(0xffb9e8d9),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL GARAGE SPENDING',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        money(p.garageCost),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Text(
                        'All vehicles, all recorded services',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, size) {
              final columns = size.maxWidth >= 650 ? 2 : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final v in p.vehicles)
                    SizedBox(
                      width: (size.maxWidth - (columns - 1) * 16) / columns,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: v.id == selected.id
                                ? const Color(0xff16756a)
                                : const Color(0xffe2eae7),
                            width: v.id == selected.id ? 1.5 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xffe4f3ed),
                                    child: Icon(
                                      Icons.directions_car_outlined,
                                      color: Color(0xff16756a),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (v.id == selected.id)
                                    const Chip(
                                      label: Text('Selected'),
                                      avatar: Icon(
                                        Icons.check_circle,
                                        size: 16,
                                      ),
                                      side: BorderSide.none,
                                      backgroundColor: Color(0xffe4f3ed),
                                    ),
                                  IconButton(
                                    tooltip: 'Edit ${v.nickname}',
                                    onPressed: () => openScreen(
                                      context,
                                      AddVehicleScreen(vehicle: v),
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                v.nickname,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${v.year} ${v.make} ${v.model}',
                                style: const TextStyle(
                                  color: Color(0xff64756f),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                v.plateNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Divider(height: 28),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      distance(v.odometer, v.unit),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(money(p.costFor(v.id!))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p.attentionFor(v) > 0
                                    ? '${p.attentionFor(v)} services need attention'
                                    : 'No services due soon',
                                style: TextStyle(
                                  color: p.attentionFor(v) > 0
                                      ? const Color(0xffb65c32)
                                      : const Color(0xff16756a),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  key: ValueKey('select-vehicle-${v.id}'),
                                  onPressed: p.switching || v.id == selected.id
                                      ? null
                                      : () => runAction(
                                          context,
                                          () => p.selectVehicle(v.id!),
                                        ),
                                  icon: Icon(
                                    v.id == selected.id
                                        ? Icons.check
                                        : Icons.swap_horiz,
                                  ),
                                  label: Text(
                                    v.id == selected.id
                                        ? 'Currently selected'
                                        : 'Select vehicle',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => openScreen(context, const AddVehicleScreen()),
            icon: const Icon(Icons.add),
            label: const Text('Add another vehicle'),
          ),
          SectionTitle(
            'Manage ${selected.nickname}',
            subtitle: 'Updates apply to your selected vehicle.',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current odometer',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    distance(selected.odometer, selected.unit),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (selected.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(selected.notes),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => updateOdometer(context),
                        icon: const Icon(Icons.speed),
                        label: const Text('Update odometer'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => openScreen(
                          context,
                          AddVehicleScreen(vehicle: selected),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit vehicle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              if (await confirmDelete(
                    context,
                    selected.nickname,
                    message:
                        'Delete ${selected.nickname} and all its service records, expenses and schedules? Your other vehicles will be kept.',
                  ) &&
                  context.mounted) {
                await runAction(
                  context,
                  () => p.deleteVehicle(selected.id!),
                  success: 'Vehicle deleted.',
                );
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete selected vehicle'),
          ),
        ],
      ],
    );
  }
}

Future<void> updateOdometer(BuildContext context) async {
  final p = context.read<MaintenanceProvider>();
  final vehicle = p.vehicle!;
  final controller = TextEditingController();
  final key = GlobalKey<FormState>();
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update odometer'),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: ${distance(vehicle.odometer, vehicle.unit)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New reading (${vehicle.unit})',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) =>
                  validNumber(v) ??
                  (double.parse(v!) < vehicle.odometer
                      ? 'The reading cannot decrease.'
                      : null),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(ctx, double.parse(controller.text));
            }
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
  // Dispose after the dialog exit transition has released its text field.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  if (result != null && context.mounted) {
    await runAction(
      context,
      () => p.updateOdometer(result, vehicleId: vehicle.id),
      success: 'Odometer updated.',
    );
  }
}
