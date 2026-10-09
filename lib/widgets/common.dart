import 'package:flutter/material.dart';

import '../models/maintenance_schedule.dart';
import '../theme/app_theme.dart';
import 'workspace.dart';
import 'feedback.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.label,
  });
  final IconData icon;
  final String title, message;
  final VoidCallback? action;
  final String? label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBadge(icon, size: 72),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.6),
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 20),
          FilledButton(onPressed: action, child: Text(label!)),
        ],
      ],
    ),
  );
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title, value;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final ServiceStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ServiceStatus.upcoming => ('Upcoming', AppColors.info),
      ServiceStatus.dueSoon => ('Due soon', AppColors.warning),
      ServiceStatus.overdue => ('Overdue', AppColors.danger),
      ServiceStatus.completed => ('Completed', AppColors.success),
    };
    return StatusBadge(
      label: label,
      color: color,
      icon: switch (status) {
        ServiceStatus.completed => Icons.check_circle_outline,
        ServiceStatus.overdue => Icons.error_outline,
        ServiceStatus.dueSoon => Icons.schedule,
        ServiceStatus.upcoming => Icons.event_outlined,
      },
    );
  }
}

Future<bool> confirmDelete(
  BuildContext context,
  String subject, {
  String? message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $subject?'),
        content: Text(
          message ?? 'Are you sure you want to delete this $subject?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.success, content: Text(success)),
      );
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
            'Could not save the change. Check your entries and try again.',
          ),
        ),
      );
    }
    return false;
  }
}

void openScreen(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
              ],
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.warning = false,
  });
  final String label, value;
  final IconData icon;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: warning ? const Color(0xfffff3f2) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: warning ? const Color(0xfff1c6c2) : AppColors.line,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              color: warning ? AppColors.danger : AppColors.primary,
              size: 19,
            ),
          ],
        ),
        const SizedBox(height: 18),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class ResponsiveTiles extends StatelessWidget {
  const ResponsiveTiles({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final columns = size.maxWidth >= 850
          ? 4
          : size.maxWidth >= 300 &&
                MediaQuery.textScalerOf(context).scale(14) < 21
          ? 2
          : 1;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children)
            SizedBox(
              width: (size.maxWidth - (columns - 1) * 12) / columns,
              child: child,
            ),
        ],
      );
    },
  );
}

EdgeInsets formPagePadding(BuildContext context) {
  final extra = ((MediaQuery.sizeOf(context).width - 760) / 2).clamp(
    0.0,
    double.infinity,
  );
  return EdgeInsets.fromLTRB(20 + extra, 20, 20 + extra, 32);
}
