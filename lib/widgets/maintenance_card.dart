import 'package:flutter/material.dart';

import '../models/maintenance_record.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'workspace.dart';

/// One service row, reused by history, expenses, and the dashboard.
class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({
    super.key,
    required this.record,
    required this.unit,
    required this.onOpen,
  });
  final MaintenanceRecord record;
  final String unit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpen,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.build_outlined, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.type,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      dateLabel(record.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                money(record.cost),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                distance(record.odometer, unit),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (record.shop.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(record.shop, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    ),
  );
}
