import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/maintenance_record.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/spending.dart';
import 'workspace.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key, required this.records, required this.now});
  final List<MaintenanceRecord> records;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final months = monthlySpending(records, now: now);
    final peak = months.fold<double>(
      0,
      (max, item) => item.total > max ? item.total : max,
    );
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending trend', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Last six calendar months \u00b7 Philippine pesos',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 196,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < months.length; i++)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${DateFormat.yMMMM().format(months[i].month)}: ${money(months[i].total)}',
                      child: Semantics(
                        label:
                            '${DateFormat.yMMMM().format(months[i].month)}: ${money(months[i].total)}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (months[i].total > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              NumberFormat.compactCurrency(
                                                locale: 'en_PH',
                                                symbol: '\u20B1',
                                                decimalDigits: 1,
                                              ).format(months[i].total),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 56,
                                        ),
                                        height:
                                            peak == 0 || months[i].total == 0
                                            ? 3
                                            : 106 * months[i].total / peak,
                                        decoration: BoxDecoration(
                                          color: months[i].total == 0
                                              ? AppColors.line
                                              : i == months.length - 1
                                              ? AppColors.primary
                                              : const Color(0xff9ccdc4),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(6),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  DateFormat.MMM().format(months[i].month),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (peak == 0)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'No recorded spending in these months.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
