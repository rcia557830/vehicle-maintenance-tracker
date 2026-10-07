import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/maintenance_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';
import '../widgets/spending_chart.dart';
import '../widgets/record_list.dart';
import 'maintenance_history_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String period = 'All time';
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final now = DateTime.now();
    final records = p.records
        .where(
          (r) =>
              period == 'All time' ||
              (r.date.year == now.year &&
                  (period == 'This year' || r.date.month == now.month)),
        )
        .toList();
    final total = records.fold(0.0, (sum, r) => sum + r.cost);
    final month = p.records
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (sum, r) => sum + r.cost);
    final year = p.records
        .where((r) => r.date.year == now.year)
        .fold(0.0, (sum, r) => sum + r.cost);
    final categories = <String, double>{};
    for (final r in records) {
      categories.update(
        r.type,
        (value) => value + r.cost,
        ifAbsent: () => r.cost,
      );
    }
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          'Expenses overview',
          subtitle: p.vehicle == null
              ? 'Record services to track their costs.'
              : 'Maintenance expenses for ${p.vehicle!.nickname}, in Philippine pesos.',
        ),
        ResponsiveTiles(
          children: [
            MetricTile(
              label: 'Total maintenance cost',
              value: money(p.totalCost),
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricTile(
              label: 'This month',
              value: money(month),
              icon: Icons.calendar_month_outlined,
            ),
            MetricTile(
              label: 'This year',
              value: money(year),
              icon: Icons.date_range_outlined,
            ),
            MetricTile(
              label: 'Average per service',
              value: money(
                p.records.isEmpty ? 0 : p.totalCost / p.records.length,
              ),
              icon: Icons.receipt_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        SpendingChart(records: p.records, now: now),
        const SizedBox(height: 24),
        const SectionTitle(
          'Service breakdown',
          subtitle: 'Choose a period to explore your recorded costs.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in ['All time', 'This year', 'This month'])
              ChoiceChip(
                label: Text(label),
                selected: period == label,
                onSelected: (_) => setState(() => period = label),
              ),
          ],
        ),
        if (records.isNotEmpty) ...[
          SectionTitle(
            'Spending by service',
            subtitle: '$period \u00b7 ${money(total)}',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  for (final category in sorted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(money(category.value)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: total == 0 ? 0 : category.value / total,
                              minHeight: 8,
                              backgroundColor: const Color(0xffedf4f0),
                              color: const Color(0xff278976),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        SectionTitle(
          'Recent expenses',
          subtitle: '${records.length} recorded services',
        ),
        if (records.isEmpty)
          EmptyState(
            icon: Icons.payments_outlined,
            title: p.records.isEmpty
                ? 'No expenses yet'
                : 'No expenses in this period',
            message: p.records.isEmpty
                ? 'Add a maintenance record and its cost to start tracking your spending.'
                : 'Choose another period to see your recorded costs.',
          ),
        if (records.isNotEmpty)
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
