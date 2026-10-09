import 'package:flutter/material.dart';

import 'maintenance_card.dart';

import '../models/maintenance_record.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'workspace.dart';

class RecordList extends StatelessWidget {
  const RecordList({
    super.key,
    required this.records,
    required this.unit,
    required this.onOpen,
  });
  final List<MaintenanceRecord> records;
  final String unit;
  final void Function(int) onOpen;
  @override
  Widget build(BuildContext context) => Panel(
    padding: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, size) {
        final table =
            size.maxWidth >= 720 &&
            MediaQuery.textScalerOf(context).scale(14) < 21;
        Widget cell(String text, {int flex = 2, bool strong = false}) =>
            Expanded(
              flex: flex,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                  color: strong ? AppColors.ink : AppColors.muted,
                ),
              ),
            );
        return Column(
          children: [
            if (table)
              Container(
                color: AppColors.field,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    cell('SERVICE', flex: 3),
                    cell('DATE'),
                    cell('ODOMETER'),
                    cell('AMOUNT'),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            for (var i = 0; i < records.length; i++) ...[
              if (table || i > 0) const Divider(),
              if (table)
                InkWell(
                  onTap: () => onOpen(records[i].id!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              const IconBadge(Icons.build_outlined, size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      records[i].type,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    if (records[i].shop.isNotEmpty)
                                      Text(
                                        records[i].shop,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        cell(dateLabel(records[i].date)),
                        cell(distance(records[i].odometer, unit)),
                        cell(money(records[i].cost), strong: true),
                        const Icon(
                          Icons.chevron_right,
                          size: 24,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                )
              else
                MaintenanceCard(
                  record: records[i],
                  unit: unit,
                  onOpen: () => onOpen(records[i].id!),
                ),
            ],
          ],
        );
      },
    ),
  );
}
