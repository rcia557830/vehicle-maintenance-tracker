import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Shared calendar field. Each screen still owns its date and validation rules.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.enabled = true,
    this.helpText,
    this.validator,
  });
  final String label;
  final DateTime? value;
  final DateTime firstDate, lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final String? helpText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    Future<void> pick() async {
      final initial = value ?? DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: initial.isBefore(firstDate)
            ? firstDate
            : initial.isAfter(lastDate)
            ? lastDate
            : initial,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: helpText ?? label,
      );
      if (date != null && context.mounted) onChanged(date);
    }

    return TextFormField(
      key: ValueKey(value),
      initialValue: value == null ? '' : dateLabel(value!),
      enabled: enabled,
      readOnly: true,
      onTap: pick,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select a date',
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        suffixIcon: IconButton(
          tooltip: 'Choose $label',
          onPressed: enabled ? pick : null,
          icon: const Icon(Icons.expand_more),
        ),
      ),
    );
  }
}
