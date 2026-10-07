import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/maintenance_schedule.dart';
import '../providers/maintenance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';
import '../widgets/driver_license_panel.dart';
import '../widgets/vehicle_overview_card.dart';
import 'add_vehicle_screen.dart';
import 'add_maintenance_screen.dart';
import 'maintenance_schedule_screen.dart';
import 'maintenance_history_screen.dart';
import 'vehicle_screen.dart';
import 'tires_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final v = p.vehicle;
    if (v == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Welcome to your garage',
            subtitle: 'A simpler way to look after every vehicle you own.',
          ),
          Panel(
            child: EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'A little care. A longer journey.',
              message: 'Keep your vehicle details, service history and running costs together. Start by adding your first vehicle.',
              label: 'Add your vehicle',
              action: () => openScreen(context, const AddVehicleScreen()),
            ),
          ),
          const SizedBox(height: 16),
          const DriverLicensePanel(),
          const SizedBox(height: 16),
          if (p.db.isCloud) ...[
            OutlinedButton.icon(
              onPressed: () => openScreen(
                context,
                Scaffold(
                  appBar: AppBar(title: const Text('Import your garage')),
                  body: const SettingsScreen(),
                ),
              ),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Import an existing local garage'),
            ),
            const SizedBox(height: 8),
          ],
          TextButton.icon(
            onPressed: () => runAction(context, p.addSampleData),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Try sample data'),
          ),
        ],
      );
    }
    final upcoming = p.upcoming
      ..sort((a, b) {
        const ranks = {
          ServiceStatus.overdue: 0,
          ServiceStatus.dueSoon: 1,
          ServiceStatus.upcoming: 2,
          ServiceStatus.completed: 3,
        };
        final order = ranks[a.status(v.odometer, unit: v.unit)]!.compareTo(
          ranks[b.status(v.odometer, unit: v.unit)]!,
        );
        return order != 0 ? order : a.date.compareTo(b.date);
      });
    final next = upcoming.firstOrNull;
    final hero = VehicleOverviewCard(
      vehicle: v,
      onUpdate: () => updateOdometer(context),
    );
    final nextPanel = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.event_note_outlined, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Next maintenance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'View all schedules',
                onPressed: () =>
                    openScreen(context, const MaintenanceScheduleScreen()),
                icon: const Icon(Icons.arrow_outward, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (next == null) ...[
            Text(
              'Nothing scheduled yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Plan your next service to stay on top of dates and mileage.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => openScreen(
                context,
                const AddMaintenanceScreen(isSchedule: true),
              ),
              icon: const Icon(Icons.add, size: 17),
              label: Text(
                MediaQuery.sizeOf(context).width < 600
                    ? 'Schedule'
                    : 'Schedule service',
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(next.type, style: Theme.of(context).textTheme.titleLarge),
                StatusChip(next.status(v.odometer, unit: v.unit)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Due ${dateLabel(next.date)}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.speed_outlined,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('At ${distance(next.odometer, p.unit)}')),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => completeMaintenance(context, next),
              icon: const Icon(Icons.check_circle_outline, size: 17),
              label: const Text('Mark completed'),
            ),
          ],
        ],
      ),
    );
    final pms = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            'Estimated Next PMS',
            subtitle: 'Based on your latest completed PMS.',
          ),
          const SizedBox(height: 8),
          Text(
            p.nextPms == null
                ? 'No estimate yet'
                : distance(p.nextPms!, p.unit),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          if (p.lastPms != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: ((v.odometer - p.lastPms!.odometer) / p.interval).clamp(
                  0.0,
                  1.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              v.odometer >= p.nextPms!
                  ? 'You have reached the estimated PMS mileage.'
                  : '${distance(p.nextPms! - v.odometer, p.unit)} until your estimated PMS.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Interval: ${distance(p.interval.toDouble(), p.unit)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            const Text(
              'Record a completed PMS to calculate your next service mileage.',
              style: TextStyle(color: AppColors.muted),
            ),
          const SizedBox(height: 18),
          const Text(
            "Follow your manufacturer's maintenance schedule.",
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
    final sortedTires = p.tires
      ..sort((a, b) => a.replacementDate.compareTo(b.replacementDate));
    final tire = sortedTires.firstOrNull;
    final tireSummary = Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.tire_repair),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tire replacement plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Open tire care',
                onPressed: () =>
                    openScreen(context, const TiresScreen(standalone: true)),
                icon: const Icon(Icons.arrow_outward, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            tire == null
                ? 'Know when to plan ahead'
                : 'Earliest target: ${tire.replacementYear}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            tire == null
                ? 'Track each tire’s manufacture date and estimate its replacement year.'
                : '${tire.position} · ${tireStatusLabel(tire.status(DateTime.now()))}',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () =>
                openScreen(context, const TiresScreen(standalone: true)),
            icon: const Icon(Icons.tire_repair, size: 18),
            label: Text(tire == null ? 'Set up tire tracking' : 'Manage tires'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Age-based estimate. Inspect for wear and damage regularly.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
    final activity = Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 10, 22, 8),
            child: SectionTitle(
              'Recent activity',
              subtitle: 'Your latest completed services.',
            ),
          ),
          if (p.records.isEmpty)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text(
                'Record your first service to start a maintenance history.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          for (final r in p.records.take(4)) ...[
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 7,
              ),
              leading: const IconBadge(Icons.build_outlined, size: 36),
              title: Text(
                r.type,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                '${dateLabel(r.date)} \u00b7 ${money(r.cost)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.muted,
              ),
              onTap: () =>
                  openScreen(context, MaintenanceDetailScreen(recordId: r.id!)),
            ),
          ],
        ],
      ),
    );
    final metrics = ResponsiveTiles(
      children: [
        MetricTile(
          label: 'Total spent',
          value: money(p.totalCost),
          icon: Icons.account_balance_wallet_outlined,
        ),
        MetricTile(
          label: 'Service records',
          value: '${p.records.length}',
          icon: Icons.receipt_long_outlined,
        ),
        MetricTile(
          label: 'Upcoming services',
          value: '${p.upcoming.length}',
          icon: Icons.event_note_outlined,
        ),
        MetricTile(
          label: 'Overdue services',
          value: '${p.overdueCount}',
          icon: Icons.warning_amber_rounded,
          warning: p.overdueCount > 0,
        ),
      ],
    );
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          PageHeading(
            'Overview',
            subtitle:
                'Everything you need to keep ${v.nickname} running smoothly.',
            actions: [
              OutlinedButton.icon(
                onPressed: () => openScreen(
                  context,
                  const AddMaintenanceScreen(isSchedule: true),
                ),
                icon: const Icon(Icons.event_outlined, size: 17),
                label: Text(
                  MediaQuery.sizeOf(context).width < 600
                      ? 'Schedule'
                      : 'Schedule service',
                ),
              ),
              FilledButton.icon(
                onPressed: () =>
                    openScreen(context, const AddMaintenanceScreen()),
                icon: const Icon(Icons.add, size: 17),
                label: Text(
                  MediaQuery.sizeOf(context).width < 600
                      ? 'Add service'
                      : 'Record a service',
                ),
              ),
            ],
          ),
          if (MediaQuery.sizeOf(context).width >= 1000) ...[
            metrics,
            const SizedBox(height: 24),
            SplitPanels(first: hero, second: nextPanel),
          ] else ...[
            hero,
            const SizedBox(height: 16),
            metrics,
            const SizedBox(height: 16),
            nextPanel,
          ],
          const SizedBox(height: 20),
          const SectionTitle(
            'Stay road-ready',
            subtitle: 'Keep important dates and tire care in view.',
          ),
          const SizedBox(height: 4),
          SplitPanels(
            first: tireSummary,
            second: const DriverLicensePanel(),
            firstFlex: 1,
            secondFlex: 1,
          ),
          const SizedBox(height: 24),
          SplitPanels(first: activity, second: pms),
        ],
      ),
    );
  }
}
