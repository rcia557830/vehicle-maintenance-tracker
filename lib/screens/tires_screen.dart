import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tire.dart';
import '../providers/maintenance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';

String tireStatusLabel(TireAgeStatus status) => switch (status) {
  TireAgeStatus.tracking => 'Age tracked',
  TireAgeStatus.inspect => 'Inspection advised',
  TireAgeStatus.dueSoon => 'Within 6 months',
  TireAgeStatus.replacementDue => 'Replacement target reached',
};
Color tireStatusColor(TireAgeStatus status) => switch (status) {
  TireAgeStatus.tracking => AppColors.primary,
  TireAgeStatus.inspect || TireAgeStatus.dueSoon => const Color(0xffa3600b),
  TireAgeStatus.replacementDue => const Color(0xffbd3a45),
};

class TiresScreen extends StatelessWidget {
  const TiresScreen({super.key, this.standalone = false});
  final bool standalone;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final tires = p.tires
      ..sort((a, b) => a.replacementDate.compareTo(b.replacementDate));
    final now = DateTime.now();
    final next = tires.firstOrNull;
    final content = p.vehicle == null
        ? const Center(
            child: EmptyState(
              icon: Icons.tire_repair,
              title: 'Choose a vehicle first',
              message:
                  'Add a vehicle in your garage to start tracking its tires.',
            ),
          )
        : RefreshIndicator(
            onRefresh: p.refresh,
            child: ListView(
              padding: const EdgeInsets.all(24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                PageHeading(
                  'Tire care',
                  subtitle:
                      'Age and replacement planning for ${p.vehicle!.nickname}.',
                  actions: [
                    FilledButton.icon(
                      onPressed: tires.length >= Tire.positions.length
                          ? null
                          : () => openScreen(context, const TireFormScreen()),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add tire'),
                    ),
                  ],
                ),
                SplitPanels(
                  firstFlex: 1,
                  secondFlex: 1,
                  first: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your tire positions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap a position to add or update its tire.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 22),
                        TirePositionMap(tires: tires),
                      ],
                    ),
                  ),
                  second: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.sidebar,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.timelapse_rounded,
                          color: Color(0xff52dcc4),
                          size: 32,
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'EARLIEST REPLACEMENT TARGET',
                          style: TextStyle(
                            color: Color(0xffb8c6da),
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          next == null ? 'Not set' : '${next.replacementYear}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          next == null
                              ? 'Add a manufacture date to see an estimate.'
                              : '${DateFormat.MMMM().format(next.replacementDate)} · ${next.position}',
                          style: const TextStyle(color: Color(0xffb8c6da)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Divider(color: Color(0xff33455e)),
                        ),
                        Text(
                          '${tires.length} of ${Tire.positions.length} positions recorded',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A planning estimate, not a guaranteed expiry date. Wear, damage and your manufacturer’s guidance may require earlier replacement.',
                          style: TextStyle(
                            color: Color(0xffb8c6da),
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                if (tires.isNotEmpty) ...[
                  Text(
                    'Tire details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, size) {
                      final columns = size.maxWidth >= 700 ? 2 : 1;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final tire in tires)
                            SizedBox(
                              width:
                                  (size.maxWidth - (columns - 1) * 16) /
                                  columns,
                              child: _TireCard(tire: tire, now: now),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                const Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How the estimate works',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manufacture month + your chosen replacement age = target month and year. The default is 6 years; adjust it to the tire or vehicle manufacturer’s guidance. The app flags tires aged 5 years for inspection and targets within 6 months.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Age tracking does not measure tread, pressure or damage. Inspect tires regularly, including the spare.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
    return standalone
        ? Scaffold(
            appBar: AppBar(title: const Text('Tire care')),
            body: content,
          )
        : content;
  }
}

class TirePositionMap extends StatelessWidget {
  const TirePositionMap({super.key, required this.tires});
  final List<Tire> tires;
  @override
  Widget build(BuildContext context) {
    Widget position(String name) {
      final tire = tires.where((t) => t.position == name).firstOrNull;
      final color = tire == null
          ? AppColors.muted
          : tireStatusColor(tire.status(DateTime.now()));
      return Semantics(
        label: '$name tire',
        button: true,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            side: BorderSide(color: color.withValues(alpha: .35)),
          ),
          onPressed: () =>
              openScreen(context, TireFormScreen(tire: tire, position: name)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tire_repair, color: color, size: 22),
              const SizedBox(height: 6),
              Text(name, style: TextStyle(color: color, fontSize: 11)),
              Text(
                tire == null ? '+ Add' : '${tire.replacementYear}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const Text(
          'FRONT',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                children: [
                  position('Front left'),
                  const SizedBox(height: 18),
                  position('Rear left'),
                ],
              ),
            ),
            Container(
              width: 90,
              height: 215,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.line, width: 2),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  Container(
                    height: 35,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffc8d8e5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Expanded(
                    child: Icon(
                      Icons.directions_car_outlined,
                      color: AppColors.muted,
                      size: 28,
                    ),
                  ),
                  Container(
                    height: 25,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffc8d8e5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  position('Front right'),
                  const SizedBox(height: 18),
                  position('Rear right'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        position('Spare'),
      ],
    );
  }
}

class _TireCard extends StatelessWidget {
  const _TireCard({required this.tire, required this.now});
  final Tire tire;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final months = tire.ageMonths(now);
    final status = tire.status(now);
    final color = tireStatusColor(status);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(Icons.tire_repair, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tire.position,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (tire.brand.isNotEmpty)
                      Text(
                        tire.brand,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit ${tire.position} tire',
                onPressed: () =>
                    openScreen(context, TireFormScreen(tire: tire)),
                icon: const Icon(Icons.edit_outlined, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                label: Text(
                  tireStatusLabel(status),
                  style: TextStyle(color: color),
                ),
                backgroundColor: color.withValues(alpha: .08),
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Estimated replacement: ${DateFormat.yMMM().format(tire.replacementDate)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Made ${DateFormat.yMMM().format(tire.manufacturedOn)} · ${months ~/ 12} yr ${months % 12} mo old',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: (months / (tire.replacementYears * 12)).clamp(0, 1),
            minHeight: 6,
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 8),
          Text(
            'Age against your ${tire.replacementYears}-year target',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (tire.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(tire.notes),
            ),
        ],
      ),
    );
  }
}

class TireFormScreen extends StatefulWidget {
  const TireFormScreen({super.key, this.tire, this.position});
  final Tire? tire;
  final String? position;
  @override
  State<TireFormScreen> createState() => _TireFormScreenState();
}

class _TireFormScreenState extends State<TireFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController year, brand, notes;
  late String position;
  late int month, replacementYears, vehicleId;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = context.read<MaintenanceProvider>();
    final tire = widget.tire;
    vehicleId = tire?.vehicleId ?? p.vehicle!.id!;
    position =
        tire?.position ??
        widget.position ??
        Tire.positions.firstWhere(
          (name) => !p.tires.any((t) => t.position == name),
          orElse: () => Tire.positions.first,
        );
    month = tire?.manufacturedOn.month ?? 1;
    replacementYears = tire?.replacementYears ?? 6;
    year = TextEditingController(
      text: tire == null ? '' : '${tire.manufacturedOn.year}',
    );
    brand = TextEditingController(text: tire?.brand ?? '');
    notes = TextEditingController(text: tire?.notes ?? '');
  }

  @override
  void dispose() {
    year.dispose();
    brand.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final tire = Tire(
      id: widget.tire?.id,
      vehicleId: vehicleId,
      position: position,
      manufacturedOn: DateTime(int.parse(year.text), month),
      brand: brand.text.trim(),
      replacementYears: replacementYears,
      notes: notes.text.trim(),
    );
    final validation = tire.validate();
    if (validation != null) {
      setState(() {
        busy = false;
        error = validation;
      });
      return;
    }
    try {
      await context.read<MaintenanceProvider>().saveTire(tire);
      if (mounted) Navigator.pop(context);
    } on ArgumentError catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = '${e.message}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Unable to save. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enteredYear = int.tryParse(year.text);
    final target =
        enteredYear != null &&
            enteredYear >= 2000 &&
            enteredYear <= DateTime.now().year
        ? DateTime(enteredYear + replacementYears, month)
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tire == null ? 'Add tire' : 'Edit tire'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                FormSection(
                  title: 'Tire information',
                  subtitle: 'Save one current tire per position. Update this entry when you replace it.',
                  icon: Icons.tire_repair,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: position,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tire position',
                      ),
                      items: [
                        for (final name in Tire.positions)
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: busy
                          ? null
                          : (value) => setState(() => position = value!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: brand,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Brand / model (optional)',
                      ),
                      maxLength: 100,
                    ),
                  ],
                ),
                FormSection(
                  title: 'Manufacture date & age limit',
                  subtitle: 'Use the manufacture date, not the purchase date. If you only know the year, use January for a conservative estimate.',
                  icon: Icons.calendar_month_outlined,
                  children: [
                    FieldPair(
                      first: DropdownButtonFormField<int>(
                        initialValue: month,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Manufacture month',
                        ),
                        items: [
                          for (var m = 1; m <= 12; m++)
                            DropdownMenuItem(
                              value: m,
                              child: Text(
                                DateFormat.MMMM().format(DateTime(2000, m)),
                              ),
                            ),
                        ],
                        onChanged: busy
                            ? null
                            : (value) => setState(() => month = value!),
                      ),
                      second: TextFormField(
                        controller: year,
                        enabled: !busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Manufacture year',
                          hintText: 'e.g. 2022',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          final y = int.tryParse(value ?? '');
                          return y == null ||
                                  y < 2000 ||
                                  y > DateTime.now().year
                              ? 'Enter a valid year.'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: replacementYears,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Replacement age limit',
                      ),
                      items: [
                        for (var age = 1; age <= 10; age++)
                          DropdownMenuItem(
                            value: age,
                            child: Text(
                              '$age ${age == 1 ? 'year' : 'years'}${age == 6 ? ' (default)' : ''}',
                            ),
                          ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) =>
                                setState(() => replacementYears = value!),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESTIMATED REPLACEMENT',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            target == null
                                ? 'Enter the manufacture year'
                                : DateFormat.yMMMM().format(target),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Follow the tire or vehicle manufacturer’s guidance. Damage or wear may require earlier replacement.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                FormSection(
                  title: 'Notes',
                  subtitle: 'Optional size, condition or inspection details.',
                  icon: Icons.notes_outlined,
                  children: [
                    TextFormField(
                      controller: notes,
                      enabled: !busy,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'Tire notes',
                      ),
                    ),
                  ],
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : save,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(busy ? 'Saving…' : 'Save tire'),
                    ),
                    OutlinedButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    if (widget.tire != null)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (!await confirmDelete(context, 'tire') ||
                                    !context.mounted) {
                                  return;
                                }
                                setState(() => busy = true);
                                final saved = await runAction(
                                  context,
                                  () => context
                                      .read<MaintenanceProvider>()
                                      .deleteTire(widget.tire!.id!),
                                );
                                if (!context.mounted) return;
                                if (saved) {
                                  Navigator.pop(context);
                                } else {
                                  setState(() => busy = false);
                                }
                              },
                        child: const Text('Delete tire'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
