import 'package:flutter/material.dart';

import '../models/maintenance_schedule.dart';
import '../theme/app_theme.dart';

import 'package:provider/provider.dart';

import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';
import '../widgets/record_list.dart';
import 'add_maintenance_screen.dart';
import 'add_vehicle_screen.dart';
import 'maintenance_schedule_screen.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  const MaintenanceHistoryScreen({super.key});
  @override
  State<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  String filter = 'All', query = '';
  bool newestFirst = true;
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    if (p.vehicle == null) {
      return ListView(
        children: [
          EmptyState(
            icon: Icons.build_outlined,
            title: 'Start with your vehicle',
            message: 'Register a vehicle before adding services.',
            label: 'Add vehicle',
            action: () => openScreen(context, const AddVehicleScreen()),
          ),
        ],
      );
    }
    final records = p.records
        .where(
          (r) =>
              (filter == 'All' || r.type == filter) &&
              '${r.type} ${r.shop} ${r.notes}'.toLowerCase().contains(
                query.toLowerCase().trim(),
              ),
        )
        .toList();
    if (!newestFirst) records.sort((a, b) => a.date.compareTo(b.date));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          'Service history',
          subtitle: 'A complete maintenance record for ${p.vehicle!.nickname}.',
          actions: [
            FilledButton.icon(
              onPressed: () =>
                  openScreen(context, const AddMaintenanceScreen()),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add maintenance record'),
            ),
          ],
        ),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: const IconBadge(Icons.event_note_outlined),
            title: const Text('Maintenance schedules'),
            subtitle: Text(
              '${p.upcoming.length} upcoming \u00b7 ${p.overdueCount} overdue',
            ),
            trailing: const Icon(Icons.arrow_forward, size: 18),
            onTap: () => openScreen(context, const MaintenanceScheduleScreen()),
          ),
        ),
        const SizedBox(height: 18),
        FieldPair(
          first: TextField(
            controller: search,
            decoration: InputDecoration(
              labelText: 'Search service history',
              hintText: 'Service, shop or notes',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        search.clear();
                        setState(() => query = '');
                      },
                    ),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          second: DropdownButtonFormField<String>(
            key: ValueKey(filter),
            initialValue: filter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filter by service',
              prefixIcon: Icon(Icons.filter_list, size: 20),
            ),
            items: [
              'All',
              ...maintenanceTypes,
            ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (value) => setState(() => filter = value!),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                '${records.length} ${records.length == 1 ? 'record' : 'records'} \u00b7 ${money(records.fold<double>(0, (sum, r) => sum + r.cost))}',
              ),
            ),
            IconButton(
              tooltip: newestFirst ? 'Sort oldest first' : 'Sort newest first',
              onPressed: () => setState(() => newestFirst = !newestFirst),
              icon: Icon(
                newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                size: 19,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (records.isEmpty)
          Panel(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: query.isNotEmpty || filter != 'All'
                  ? 'No matching records'
                  : 'No maintenance records yet',
              message: query.isNotEmpty || filter != 'All'
                  ? 'Try a different search or service filter.'
                  : 'Your completed services will appear here.',
              label: query.isNotEmpty || filter != 'All'
                  ? 'Clear filters'
                  : 'Add maintenance record',
              action: query.isNotEmpty || filter != 'All'
                  ? () {
                      search.clear();
                      setState(() {
                        query = '';
                        filter = 'All';
                      });
                    }
                  : () => openScreen(context, const AddMaintenanceScreen()),
            ),
          )
        else
          RecordList(
            records: records,
            unit: p.unit,
            onOpen: (id) =>
                openScreen(context, MaintenanceDetailScreen(recordId: id)),
          ),
      ],
    );
  }
}

class MaintenanceDetailScreen extends StatelessWidget {
  const MaintenanceDetailScreen({super.key, required this.recordId});
  final int recordId;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final matches = p.records.where((r) => r.id == recordId);
    final MaintenanceRecord? r = matches.isEmpty ? null : matches.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Service details')),
      body: r == null
          ? SingleChildScrollView(
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Record unavailable',
                message: 'This record is no longer available.',
                label: 'Go back',
                action: () => Navigator.pop(context),
              ),
            )
          : ListView(
              padding: formPagePadding(context),
              children: [
                PageHeading(
                  r.type,
                  subtitle:
                      'Service record for ${p.vehicle?.nickname ?? 'your vehicle'}.',
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(ServiceStatus.completed),
                ),
                const SizedBox(height: 20),
                FieldPair(
                  first: MetricTile(
                    icon: Icons.payments_outlined,
                    label: 'Cost',
                    value: money(r.cost),
                  ),
                  second: MetricTile(
                    icon: Icons.speed,
                    label: 'Service odometer',
                    value: distance(r.odometer, p.unit),
                  ),
                ),
                const SizedBox(height: 20),
                FormSection(
                  title: 'Service information',
                  subtitle: 'The details of this completed service.',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    DetailLine(
                      icon: Icons.calendar_today_outlined,
                      text: 'Service date: ${dateLabel(r.date)}',
                    ),
                    const Divider(height: 24),
                    Text(
                      'Service provider / shop',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    SelectableText(r.shop.isEmpty ? 'Not provided' : r.shop),
                    const SizedBox(height: 20),
                    Text('Notes', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 6),
                    SelectableText(r.notes.isEmpty ? 'No notes' : r.notes),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () =>
                      openScreen(context, AddMaintenanceScreen(record: r)),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit record'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () async {
                    if (await confirmDelete(context, 'maintenance record') &&
                        context.mounted) {
                      final ok = await runAction(
                        context,
                        () => p.deleteRecord(r.id!),
                      );
                      if (ok && context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete record'),
                ),
              ],
            ),
    );
  }
}
