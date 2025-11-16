import 'package:flutter/material.dart';
import 'package:pao_tracker/utils/colors.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick PAO', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: valuesInMonths.map((m) {
            final isSelected = selectedMonths == m;
            return ChoiceChip(
              label: Text('${m}M'),
              selected: isSelected,
              onSelected: (_) => onSelectedMonths(isSelected ? null : m),
              elevation: 0,
              selectedColor: AppColors.primaryContainer,
              backgroundColor: AppColors.surfaceVariant,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
