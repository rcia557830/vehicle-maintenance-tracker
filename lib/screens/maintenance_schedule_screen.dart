import 'package:flutter/material.dart';

import '../widgets/feedback.dart';
import 'add_vehicle_screen.dart';

import 'package:provider/provider.dart';

import '../models/maintenance_schedule.dart';
import '../providers/maintenance_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';
import 'add_maintenance_screen.dart';

class MaintenanceScheduleScreen extends StatefulWidget {
  const MaintenanceScheduleScreen({super.key});
  @override
  State<MaintenanceScheduleScreen> createState() =>
      _MaintenanceScheduleScreenState();
}

class _MaintenanceScheduleScreenState extends State<MaintenanceScheduleScreen> {
  String filter = 'Upcoming';
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final filtered = p.schedules
        .where(
          (s) => switch (filter) {
            'Upcoming' => !s.completed,
            'Overdue' =>
              s.status(p.vehicle?.odometer ?? 0, unit: p.unit) ==
                  ServiceStatus.overdue,
            'Completed' => s.completed,
            _ => true,
          },
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance schedules')),
      floatingActionButton: p.vehicle == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openScreen(
                context,
                const AddMaintenanceScreen(isSchedule: true),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Schedule'),
            ),
      body: ListView(
        padding: formPagePadding(context).copyWith(bottom: 96),
        children: [
          PageHeading(
            'Service schedule',
            subtitle:
                'Plan ahead for ${p.vehicle?.nickname ?? 'your vehicle'} and track every due date.',
          ),
          const InfoBanner(
            'Due soon means within 7 days or 1,000 km (621 mi). A service is overdue when either its date or mileage is reached.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in ['Upcoming', 'Overdue', 'Completed', 'All'])
                ChoiceChip(
                  label: Text(label),
                  selected: filter == label,
                  onSelected: (_) => setState(() => filter = label),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Panel(
              child: EmptyState(
                icon: Icons.event_available_outlined,
                title: p.vehicle == null
                    ? 'Start with your vehicle'
                    : 'No services in this view',
                message: p.vehicle == null
                    ? 'Add a vehicle to plan its maintenance.'
                    : 'Plan a service by date and odometer to see its status here.',
                label: p.vehicle == null ? 'Add vehicle' : 'Schedule service',
                action: () => openScreen(
                  context,
                  p.vehicle == null
                      ? const AddVehicleScreen()
                      : const AddMaintenanceScreen(isSchedule: true),
                ),
              ),
            ),
          for (final s in filtered)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBadge(Icons.build_outlined, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.type,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Schedule options',
                          onSelected: (action) async {
                            if (action == 'edit') {
                              openScreen(
                                context,
                                AddMaintenanceScreen(
                                  isSchedule: true,
                                  schedule: s,
                                ),
                              );
                            }
                            if (action == 'delete' &&
                                await confirmDelete(context, 'schedule') &&
                                context.mounted) {
                              await runAction(
                                context,
                                () => p.deleteSchedule(s.id!),
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            if (!s.completed)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit schedule'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete schedule'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    StatusChip(
                      s.status(p.vehicle?.odometer ?? 0, unit: p.unit),
                    ),
                    const SizedBox(height: 8),
                    DetailLine(
                      icon: Icons.calendar_today_outlined,
                      text: 'Due ${dateLabel(s.date)}',
                    ),
                    DetailLine(
                      icon: Icons.speed_outlined,
                      text: 'At ${distance(s.odometer, p.unit)}',
                    ),
                    DetailLine(
                      icon: Icons.notifications_outlined,
                      text:
                          s.reminder &&
                              p.remindersEnabled &&
                              p.notifications.supported
                          ? 'Date reminder enabled'
                          : 'Date reminder off',
                    ),
                    if (s.notes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(s.notes),
                      ),
                    if (!s.completed) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => completeMaintenance(context, s),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Mark completed'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> completeMaintenance(
  BuildContext context,
  MaintenanceSchedule s,
) async {
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Complete this service?'),
      content: const Text(
        'Add the actual service date, odometer and cost to save it in your history, or just mark the schedule completed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'only'),
          child: const Text('Mark only'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'record'),
          child: const Text('Add service record'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (choice == 'record') {
    openScreen(
      context,
      AddMaintenanceScreen(schedule: s, completeScheduleId: s.id),
    );
  }
  if (choice == 'only') {
    await runAction(
      context,
      () => context.read<MaintenanceProvider>().completeSchedule(s.id!, null),
      success: 'Service marked completed.',
    );
  }
}
