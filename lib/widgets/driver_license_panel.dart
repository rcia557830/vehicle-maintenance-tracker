import 'package:flutter/material.dart';

import 'license_status.dart';

import 'package:provider/provider.dart';

import '../models/driver_license.dart';
import '../providers/maintenance_provider.dart';
import '../screens/driver_license_screen.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common.dart';
import 'workspace.dart';

class DriverLicensePanel extends StatelessWidget {
  const DriverLicensePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final license = p.driverLicense;
    final now = DateTime.now();
    final status = license?.status(now);
    final color = licenseStatusColor(status);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(Icons.badge_outlined, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "LTO driver's license",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (license != null)
                IconButton(
                  tooltip: 'Edit LTO license',
                  onPressed: p.error == null
                      ? () => openScreen(context, const DriverLicenseScreen())
                      : null,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (license == null) ...[
            const Text(
              'Keep your 5- or 10-year license expiry in view, across every vehicle.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: p.error == null
                  ? () => openScreen(context, const DriverLicenseScreen())
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add LTO license'),
            ),
          ] else ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  dateLabel(license.expiresOn),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                LicenseStatusBadge(license: license),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${license.validityYears}-year validity \u00b7 ${license.countdown(now)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
            if (status != LicenseExpiryStatus.tracked) ...[
              const SizedBox(height: 8),
              const Text('Update the expiry date after renewing your license.'),
            ],
          ],
        ],
      ),
    );
  }
}
