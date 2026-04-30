import 'package:flutter/material.dart';

class WeightEntrySection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onSave;

  const WeightEntrySection({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: formKey,
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Current weight',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (double.tryParse(value) == null) return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
