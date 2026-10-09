import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.title, {
    super.key,
    required this.subtitle,
    this.actions = const [],
  });
  final String title, subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 24),
    child: LayoutBuilder(
      builder: (context, size) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontSize: size.maxWidth < 500 ? 27 : 30),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          ],
        );
        if (size.maxWidth > 740 && actions.isNotEmpty) {
          return Row(
            children: [
              Expanded(child: heading),
              const SizedBox(width: 16),
              Wrap(spacing: 8, children: actions),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        );
      },
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 1,
    shadowColor: const Color(0x1017283f),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class SplitPanels extends StatelessWidget {
  const SplitPanels({
    super.key,
    required this.first,
    required this.second,
    this.firstFlex = 3,
    this.secondFlex = 2,
  });
  final Widget first, second;
  final int firstFlex, secondFlex;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => size.maxWidth >= 780
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: firstFlex, child: first),
              const SizedBox(width: 20),
              Expanded(flex: secondFlex, child: second),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 16), second],
          ),
  );
}

class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.color = AppColors.primary,
    this.size = 42,
  });
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}

class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.icon,
  });
  final String title, subtitle;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    ),
  );
}

class FieldPair extends StatelessWidget {
  const FieldPair({super.key, required this.first, required this.second});
  final Widget first, second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => size.maxWidth >= 520
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 16),
              Expanded(child: second),
            ],
          )
        : Column(children: [first, const SizedBox(height: 16), second]),
  );
}

class DetailLine extends StatelessWidget {
  const DetailLine({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    ),
  );
}
