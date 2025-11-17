import 'package:flutter/material.dart';
// import 'package:pao_tracker/utils/colors.dart'; // No longer needed

class PAOOptions extends StatelessWidget {
  final List<int> valuesInMonths;
  final int? selectedMonths;
  final void Function(int?) onSelectedMonths;

  const PAOOptions({
    super.key,
    required this.valuesInMonths,
    required this.selectedMonths,
    required this.onSelectedMonths,
  });

  @override
  Widget build(BuildContext context) {
    // --- NEW: Get theme ---
    final colorScheme = Theme.of(context).colorScheme;

    // Map months to slider index
    final currentIndex = selectedMonths != null
        ? valuesInMonths.indexOf(selectedMonths!)
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select PAO',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${valuesInMonths.first}M'),
            Text('${valuesInMonths.last}M'),
          ],
        ),
        Slider(
          value: currentIndex.toDouble(),
          min: 0,
          max: (valuesInMonths.length - 1).toDouble(),
          divisions: valuesInMonths.length - 1,
          label: '${valuesInMonths[currentIndex]}M',
          onChanged: (value) {
            onSelectedMonths(valuesInMonths[value.round()]);
          },
          // --- UPDATED: Use theme colors ---
          activeColor: colorScheme.secondary,
          inactiveColor: colorScheme.surfaceVariant,
        ),
        if (selectedMonths != null)
          Text(
            'Selected: ${selectedMonths}M',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
      ],
    );
  }
}