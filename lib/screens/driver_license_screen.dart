import 'package:flutter/material.dart';

import '../widgets/feedback.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/license_status.dart';

import 'package:provider/provider.dart';

import '../models/driver_license.dart';
import '../providers/maintenance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';

class DriverLicenseScreen extends StatefulWidget {
  const DriverLicenseScreen({super.key});

  @override
  State<DriverLicenseScreen> createState() => _DriverLicenseScreenState();
}

class _DriverLicenseScreenState extends State<DriverLicenseScreen> {
  final form = GlobalKey<FormState>();
  DriverLicense? original;
  DateTime? expiry;
  int validity = 5;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    original = context.read<MaintenanceProvider>().driverLicense;
    validity = original?.validityYears ?? 5;
    expiry = original?.expiresOn;
  }

  void setExpiry(DateTime date) {
    setState(() {
      expiry = date;
    });
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<MaintenanceProvider>().saveDriverLicense(
        DriverLicense(validityYears: validity, expiresOn: expiry!),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Unable to save your license. Check your connection and try again.';
        });
      }
    }
  }

  Future<void> remove() async {
    if (busy) return;
    if (!await confirmDelete(
          context,
          'license tracking',
          message: 'Remove this saved expiry date and its reminders?',
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await context.read<MaintenanceProvider>().removeDriverLicense();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Unable to remove license tracking. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = expiry == null
        ? null
        : DriverLicense(validityYears: validity, expiresOn: expiry!);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('LTO license expiry')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const PageHeading(
                    'Your license, on time',
                    subtitle:
                        'One personal license, shared across your garage.',
                  ),
                  FormSection(
                    title: "Driver's license details",
                    subtitle: 'Use the validity and expiry date shown on your LTO license.',
                    icon: Icons.badge_outlined,
                    children: [
                      const Text('License validity'),
                      const SizedBox(height: 10),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 5, label: Text('5 years')),
                          ButtonSegment(value: 10, label: Text('10 years')),
                        ],
                        selected: {validity},
                        onSelectionChanged: busy
                            ? null
                            : (values) =>
                                  setState(() => validity = values.single),
                      ),
                      const SizedBox(height: 20),
                      DatePickerField(
                        key: const ValueKey('license-expiry'),
                        label: 'Expiry date on your license',
                        value: expiry,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100, 12, 31),
                        helpText: 'EXPIRY DATE PRINTED ON YOUR LICENSE',
                        enabled: !busy,
                        onChanged: setExpiry,
                        validator: (_) => expiry == null
                            ? 'Select your license expiry date.'
                            : preview!.validate(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'LTO expiry follows your birthday. Enter the printed date instead of adding years to the issue date. Choose 10 years only if your license was issued with that validity.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      if (original != null &&
                          original!.expiresOn.year + validity <= 2100) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => setExpiry(
                                  DriverLicense.estimateRenewal(
                                    original!.expiresOn,
                                    validity,
                                  ),
                                ),
                          icon: const Icon(
                            Icons.event_repeat_outlined,
                            size: 18,
                          ),
                          label: Text('Estimate $validity-year renewal'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adds $validity years to ${dateLabel(original!.expiresOn)}. Check the result against your renewed license before saving.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                  if (preview != null) ...[
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LicenseStatusBadge(license: preview),
                          const SizedBox(height: 8),
                          Text(
                            dateLabel(preview.expiresOn),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(preview.countdown(DateTime.now())),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'Your dashboard highlights expiry within 60 days. Android expiry notifications follow your reminder preference in Settings.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  if (error != null) ...[
                    InfoBanner(
                      error!,
                      color: AppColors.danger,
                      icon: Icons.error_outline,
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    onPressed: busy ? null : save,
                    icon: BusyIcon(busy: busy),
                    label: Text(busy ? 'Saving...' : 'Save license'),
                  ),
                  if (original != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: busy ? null : remove,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove license tracking'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
