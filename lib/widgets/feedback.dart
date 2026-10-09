import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Text and an icon accompany every color, so status is never color-only.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon = Icons.info_outline,
  });
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: color.withValues(alpha: .16)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner(
    this.message, {
    super.key,
    this.color = AppColors.info,
    this.icon = Icons.info_outline,
  });
  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

class BusyIcon extends StatelessWidget {
  const BusyIcon({super.key, required this.busy, this.icon = Icons.check});
  final bool busy;
  final IconData icon;
  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Saving',
          ),
        )
      : Icon(icon, size: 18);
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              semanticsLabel: 'Loading garage',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Opening your garage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Loading your vehicles and saved records.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}
