import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/maintenance_provider.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';
import '../widgets/cloud_account_panel.dart';
import '../widgets/driver_license_panel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeading(
          'Preferences',
          subtitle: 'Personalize how you manage your garage.',
        ),
        SplitPanels(
          first: Column(
            children: [
              FormSection(
                title: 'Garage preferences',
                subtitle: 'Applies to every vehicle.',
                icon: Icons.tune_outlined,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    key: ValueKey(p.unit),
                    initialValue: p.unit,
                    decoration: const InputDecoration(
                      labelText: 'Odometer unit',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'km',
                        child: Text('Kilometers (km)'),
                      ),
                      DropdownMenuItem(value: 'mi', child: Text('Miles (mi)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        runAction(
                          context,
                          () => p.setUnit(value),
                          success: 'Distance units updated.',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Converts all saved distances. PMS intervals are interpreted in the chosen unit.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Maintenance & license notifications'),
                    subtitle: Text(
                      p.notifications.supported
                          ? 'Service reminders and license alerts 60, 30 and 7 days before expiry, and on the day, around 9 AM. Android may delay delivery to save battery.'
                          : 'Scheduled notifications are available in the Android app. Service and license expiry alerts remain visible on the dashboard.',
                    ),
                    value: p.notifications.supported && p.remindersEnabled,
                    onChanged: p.notifications.supported
                        ? (value) => runAction(
                            context,
                            () => p.setNotifications(value),
                          )
                        : null,
                  ),
                  if (p.notificationWarning != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(p.notificationWarning!),
                    ),
                ],
              ),
              FormSection(
                title: 'Service interval',
                subtitle: p.vehicle == null
                    ? 'Default for new vehicles.'
                    : 'For ${p.vehicle!.nickname} only.',
                icon: Icons.event_repeat_outlined,
                children: [
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    key: ValueKey(p.interval),
                    initialValue: p.interval,
                    decoration: InputDecoration(
                      labelText: 'PMS interval (${p.unit})',
                    ),
                    items: [8000, 9000, 10000]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v ${p.unit}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        runAction(
                          context,
                          () => p.setInterval(value),
                          success: 'PMS interval updated.',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Used to estimate your next PMS from the latest completed service. Follow the interval recommended for your vehicle.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          second: Column(
            children: [
              const DriverLicensePanel(),
              const SizedBox(height: 20),
              FormSection(
                title: 'Your data',
                subtitle: p.db.isCloud
                    ? 'A private workspace in your account.'
                    : 'Local workspace preview.',
                icon: Icons.storage_outlined,
                children: [
                  Text(
                    '${p.vehicles.length} vehicles in your garage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('${p.allRecords.length} service records saved'),
                  const SizedBox(height: 16),
                  Text(
                    p.db.isCloud
                        ? 'Records are saved to your Supabase account. Refresh the garage to load changes from another device.'
                        : 'These are local records. The connected app uses your Supabase account.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const CloudAccountPanel(),
              Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: const Text('Load sample data'),
                      subtitle: Text(
                        p.vehicle == null
                            ? 'Explore a sample vehicle and service history.'
                            : 'Available when your garage is empty.',
                      ),
                      enabled: p.vehicle == null,
                      onTap: p.vehicle == null
                          ? () => runAction(
                              context,
                              p.addSampleData,
                              success: 'Sample data added.',
                            )
                          : null,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About Motorcare'),
                      subtitle: const Text(
                        'Vehicle Maintenance Tracker \u00b7 1.0.0',
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Motorcare',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.directions_car_outlined,
                          size: 40,
                        ),
                        children: const [
                          Text(
                            'Your vehicle maintenance, tire replacement plans, service schedules and expenses in one organized workspace. Vehicle information is entered manually.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
