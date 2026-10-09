import 'package:flutter/material.dart';

import '../widgets/feedback.dart';

import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../providers/maintenance_provider.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key, this.vehicle});
  final Vehicle? vehicle;
  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> fields;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    fields = [
      v?.nickname ?? '',
      v?.make ?? '',
      v?.model ?? '',
      '${v?.year ?? DateTime.now().year}',
      v?.plateNumber ?? '',
      v?.odometer.toString() ?? '',
      v?.notes ?? '',
    ].map((s) => TextEditingController(text: s)).toList();
  }

  @override
  void dispose() {
    for (final c in fields) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    final p = context.read<MaintenanceProvider>();
    final ok = await runAction(
      context,
      () => p.saveVehicle(
        Vehicle(
          id: widget.vehicle?.id,
          nickname: fields[0].text.trim(),
          make: fields[1].text.trim(),
          model: fields[2].text.trim(),
          year: int.parse(fields[3].text),
          plateNumber: fields[4].text.trim().toUpperCase(),
          odometer: double.parse(fields[5].text),
          unit: p.unit,
          notes: fields[6].text.trim(),
        ),
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
    }
  }

  Widget field(int i) => TextFormField(
    enabled: !saving,
    controller: fields[i],
    textInputAction: i == 6 ? TextInputAction.newline : TextInputAction.next,
    textCapitalization: i == 4
        ? TextCapitalization.characters
        : TextCapitalization.words,
    decoration: InputDecoration(
      labelText: [
        'Vehicle name / nickname',
        'Manufacturer / make',
        'Model',
        'Year',
        'Plate number',
        'Current odometer (${context.read<MaintenanceProvider>().unit})',
        'Notes (optional)',
      ][i],
    ),
    keyboardType: i == 3
        ? TextInputType.number
        : i == 5
        ? const TextInputType.numberWithOptions(decimal: true)
        : i == 6
        ? TextInputType.multiline
        : TextInputType.text,
    maxLines: i == 6 ? 3 : 1,
    validator: (value) {
      if (i == 6) return null;
      if (i == 4) {
        return requiredText(value) ??
            context.read<MaintenanceProvider>().plateError(
              value!,
              exceptId: widget.vehicle?.id,
            );
      }
      if (i == 3) {
        final year = int.tryParse(value ?? '');
        return year == null || year < 1886 || year > DateTime.now().year + 1
            ? 'Enter a valid vehicle year.'
            : null;
      }
      if (i == 5) {
        final error = validNumber(value);
        if (error != null) return error;
        return double.parse(value!) < (widget.vehicle?.odometer ?? 0)
            ? 'The odometer cannot be lower than the saved reading.'
            : null;
      }
      return requiredText(value);
    },
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.vehicle == null ? 'Add vehicle' : 'Edit vehicle'),
    ),
    body: Form(
      key: form,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: formPagePadding(context),
        children: [
          PageHeading(
            widget.vehicle == null
                ? 'Make room in your garage'
                : 'Vehicle details',
            subtitle: 'Keep the essentials accurate so every service stays with the right vehicle.',
          ),
          FormSection(
            title: 'Vehicle identity',
            subtitle: 'The details that make it yours.',
            icon: Icons.directions_car_outlined,
            children: [
              field(0),
              const SizedBox(height: 16),
              FieldPair(first: field(1), second: field(2)),
              const SizedBox(height: 16),
              FieldPair(first: field(3), second: field(4)),
            ],
          ),
          FormSection(
            title: 'Mileage & notes',
            subtitle: 'A starting point for your maintenance records.',
            icon: Icons.speed_outlined,
            children: [
              field(5),
              const SizedBox(height: 10),
              Text(
                'Distance unit: ${context.watch<MaintenanceProvider>().unit}. Change units for your garage in Settings.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              field(6),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: saving ? null : save,
                icon: BusyIcon(busy: saving),
                label: Text(saving ? 'Saving...' : 'Save vehicle'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
