import 'package:flutter/material.dart';

import '../widgets/feedback.dart';
import '../widgets/date_picker_field.dart';

import 'package:provider/provider.dart';

import '../models/maintenance_record.dart';
import '../models/maintenance_schedule.dart';
import '../providers/maintenance_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/common.dart';
import '../widgets/workspace.dart';

// Shared form keeps the fields and validation consistent for records and schedules.
class AddMaintenanceScreen extends StatefulWidget {
  const AddMaintenanceScreen({
    super.key,
    this.record,
    this.schedule,
    this.isSchedule = false,
    this.completeScheduleId,
  });
  final MaintenanceRecord? record;
  final MaintenanceSchedule? schedule;
  final bool isSchedule;
  final int? completeScheduleId;
  @override
  State<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends State<AddMaintenanceScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController odometer, cost, shop, notes;
  String? type;
  late final int vehicleId;
  late DateTime date;
  bool reminder = true, saving = false;
  @override
  void initState() {
    super.initState();
    final r = widget.record;
    final s = widget.schedule;
    vehicleId =
        r?.vehicleId ??
        s?.vehicleId ??
        context.read<MaintenanceProvider>().vehicle!.id!;
    type = r?.type ?? s?.type;
    date = r?.date ?? (widget.isSchedule ? s?.date : null) ?? DateTime.now();
    odometer = TextEditingController(
      text:
          (r?.odometer ??
                  (widget.isSchedule
                      ? s?.odometer
                      : context.read<MaintenanceProvider>().vehicle?.odometer))
              ?.toString() ??
          '',
    );
    cost = TextEditingController(text: r?.cost.toString() ?? '');
    shop = TextEditingController(text: r?.shop ?? '');
    notes = TextEditingController(text: r?.notes ?? s?.notes ?? '');
    reminder =
        s?.reminder ??
        context.read<MaintenanceProvider>().notifications.supported;
  }

  @override
  void dispose() {
    for (final c in [odometer, cost, shop, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    final p = context.read<MaintenanceProvider>();
    if (p.vehicle == null) return;
    setState(() => saving = true);
    final ok = await runAction(context, () async {
      if (widget.isSchedule) {
        await p.saveSchedule(
          MaintenanceSchedule(
            id: widget.schedule?.id,
            vehicleId: vehicleId,
            type: type!,
            date: DateTime(date.year, date.month, date.day),
            odometer: double.parse(odometer.text),
            notes: notes.text.trim(),
            reminder: reminder,
            completed: widget.schedule?.completed ?? false,
          ),
        );
      } else {
        final record = MaintenanceRecord(
          id: widget.record?.id,
          vehicleId: vehicleId,
          type: type!,
          date: DateTime(date.year, date.month, date.day),
          odometer: double.parse(odometer.text),
          cost: double.parse(cost.text),
          shop: shop.text.trim(),
          notes: notes.text.trim(),
        );
        if (widget.completeScheduleId != null) {
          await p.completeSchedule(widget.completeScheduleId!, record);
        } else {
          await p.saveRecord(record);
        }
      }
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing =
        widget.record != null || (widget.isSchedule && widget.schedule != null);
    final unit = context.watch<MaintenanceProvider>().unit;
    final remindersSupported = context
        .read<MaintenanceProvider>()
        .notifications
        .supported;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.completeScheduleId != null
              ? 'Complete service'
              : '${editing ? 'Edit' : 'Add'} ${widget.isSchedule ? 'schedule' : 'maintenance'}',
        ),
      ),
      body: Form(
        key: form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: formPagePadding(context),
          children: [
            PageHeading(
              widget.isSchedule
                  ? 'Plan ahead'
                  : editing
                  ? 'Update your service'
                  : 'Record a service',
              subtitle:
                  'For ${context.read<MaintenanceProvider>().vehicles.where((v) => v.id == vehicleId).firstOrNull?.nickname ?? 'your vehicle'}',
            ),
            FormSection(
              title: widget.isSchedule ? 'Plan a service' : 'Service details',
              subtitle: 'Choose the maintenance type, date and mileage.',
              icon: Icons.build_outlined,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance type',
                  ),
                  items: maintenanceTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: saving ? null : (v) => type = v,
                  validator: (v) =>
                      v == null ? 'Choose a maintenance type.' : null,
                ),
                const SizedBox(height: 16),
                DatePickerField(
                  label: widget.isSchedule ? 'Due date' : 'Service date',
                  value: date,
                  firstDate: DateTime(1900),
                  lastDate: widget.isSchedule ? DateTime(2100) : DateTime.now(),
                  enabled: !saving,
                  onChanged: (value) => setState(() => date = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: !saving,
                  controller: odometer,
                  decoration: InputDecoration(
                    labelText:
                        '${widget.isSchedule ? 'Due odometer' : 'Service odometer'} ($unit)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: validNumber,
                ),
                const SizedBox(height: 16),
              ],
            ),
            if (!widget.isSchedule) ...[
              FormSection(
                title: 'Cost & provider',
                subtitle: 'Track the cost of keeping your vehicle running.',
                icon: Icons.receipt_long_outlined,
                children: [
                  TextFormField(
                    enabled: !saving,
                    controller: cost,
                    decoration: const InputDecoration(
                      labelText: 'Cost (PHP)',
                      prefixText: '\u20B1 ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: validNumber,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    enabled: !saving,
                    controller: shop,
                    decoration: const InputDecoration(
                      labelText: 'Service provider / shop (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const InfoBanner(
                    'Service readings are historical. Update your current odometer separately in Garage.',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
            FormSection(
              title: 'Additional details',
              subtitle: 'Anything you want to remember about this service.',
              icon: Icons.notes_outlined,
              children: [
                TextFormField(
                  enabled: !saving,
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                if (widget.isSchedule)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder enabled'),
                    subtitle: Text(
                      remindersSupported
                          ? 'At about 9 AM on the due date. Also enable notifications in Settings.'
                          : 'Scheduled notifications are available in the Android app.',
                    ),
                    value: remindersSupported && reminder,
                    onChanged: remindersSupported && !saving
                        ? (v) => setState(() => reminder = v)
                        : null,
                  ),
                const SizedBox(height: 20),
              ],
            ),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: BusyIcon(busy: saving),
              label: Text(
                saving
                    ? 'Saving...'
                    : 'Save ${widget.isSchedule ? 'schedule' : 'record'}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
