import 'package:flutter/material.dart';

import '../models/driver_license.dart';
import '../theme/app_theme.dart';
import 'feedback.dart';

Color licenseStatusColor(LicenseExpiryStatus? status) => switch (status) {
  LicenseExpiryStatus.expired => AppColors.danger,
  LicenseExpiryStatus.dueSoon ||
  LicenseExpiryStatus.expiresToday => AppColors.warning,
  _ => AppColors.success,
};

class LicenseStatusBadge extends StatelessWidget {
  const LicenseStatusBadge({super.key, required this.license});
  final DriverLicense license;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return StatusBadge(
      label: license.statusLabel(now),
      color: licenseStatusColor(license.status(now)),
      icon: Icons.badge_outlined,
    );
  }
}
