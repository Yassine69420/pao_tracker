import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_item.dart';
import 'package:pao_tracker/screens/widgets/photo_picker.dart';
import 'package:pao_tracker/screens/widgets/pao_options.dart';
import 'package:pao_tracker/screens/widgets/favorite_button.dart';
import '../utils/colors.dart';
import '../providers/product_provider.dart';
import '../data/database_helper.dart';

class AddEditScreen extends ConsumerStatefulWidget {
  final ProductItem? product;
  const AddEditScreen({super.key, this.product});

  @override
  ConsumerState<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends ConsumerState<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _labelController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _openedDate = DateTime.now();
  String? _photoPath;
  bool _favorite = false;
  bool _isLoading = false;

  // Keep last selected PAO in months for convenience
  int? _selectedPaoMonths;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _brandController.text = widget.product!.brand ?? '';
      _labelController.text = widget.product!.label;
      _notesController.text = widget.product!.notes?.join('\n') ?? '';
      _openedDate = widget.product!.openedDate;
      _photoPath = widget.product!.photoPath;
      _favorite = widget.product!.favorite;

      // Try to parse label like "12M"
      final match = RegExp(
        r"(\d+)\s*M",
        caseSensitive: false,
      ).firstMatch(widget.product!.label);
      if (match != null) {
        _selectedPaoMonths = int.tryParse(match.group(1)!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _labelController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          FavoriteButton(
            isFavorite: _favorite,
            onChanged: (v) => setState(() => _favorite = v),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PhotoPicker(
              photoPath: _photoPath,
              onPick: (path) => setState(() => _photoPath = path),
              onRemove: () => setState(() => _photoPath = null),
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                label: const Text('Product Name'),
                hintText: 'e.g., Foundation, Serum, Mascara',
                prefixIcon: const Icon(Icons.inventory_2_outlined),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Please enter product name'
                  : null,
            ),
            const SizedBox(height: 12),

            // Brand and opened date on a row for MD3 compactness
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand field
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    label: const Text('Brand (Optional)'),
                    prefixIcon: const Icon(Icons.business_outlined),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
            
                const SizedBox(height: 20),
            
                // Label for opened date
                const Text(
                  "Opened Date",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            
                const SizedBox(height: 8),
            
                // Opened date field
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(_openedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // PAO options as segmented buttons + editable input
            PAOOptions(
              valuesInMonths: const [3, 6, 12, 24, 36, 48],
              selectedMonths: _selectedPaoMonths,
              onSelectedMonths: (val) {
                setState(() {
                  _selectedPaoMonths = val;
                  _labelController.text = val == null ? '' : '${val}M';
                });
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                label: const Text('PAO Label'),
                hintText: 'e.g., 6M, 12M, 24M',
                prefixIcon: const Icon(Icons.label_outlined),
                helperText: 'Period After Opening (e.g., 6M = 6 months)',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return 'Please enter PAO label';
                final parsed = _parsePAOLabel(value);
                if (parsed == null)
                  return 'Invalid format. Use format like 6M, 12M, etc.';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                label: const Text('Notes (Optional)'),
                hintText: 'Add any additional notes\nOne note per line',
                prefixIcon: const Icon(Icons.note_outlined),
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEditing ? 'Update Product' : 'Add Product',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _openedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );

    if (picked != null) setState(() => _openedDate = picked);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final shelfLifeDays = _parsePAOLabel(_labelController.text.trim());
    if (shelfLifeDays == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PAO label format'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final notes = _notesController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final brandValue = _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim();

      if (widget.product != null) {
        // update existing product
        final updated = widget.product!.copyWith(
          name: _nameController.text.trim(),
          brand: brandValue,
          openedDate: _openedDate,
          shelfLifeDays: shelfLifeDays,
          label: _labelController.text.trim(),
          photoPath: _photoPath,
          favorite: _favorite,
          notes: notes.isEmpty ? null : notes,
        );

        await ref.read(productListProvider.notifier).update(updated);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // create new product
        final newProduct = ProductItem(
          id: DatabaseHelper.generateId(),
          name: _nameController.text.trim(),
          brand: brandValue,
          openedDate: _openedDate,
          shelfLifeDays: shelfLifeDays,
          label: _labelController.text.trim(),
          photoPath: _photoPath,
          favorite: _favorite,
          notes: notes.isEmpty ? null : notes,
        );

        await ref.read(productListProvider.notifier).create(newProduct);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int? _parsePAOLabel(String label) {
    final trimmed = label.trim().toUpperCase();
    final match = RegExp(r'(\d+)\s*M').firstMatch(trimmed);
    if (match != null) {
      final months = int.tryParse(match.group(1)!);
      if (months != null && months > 0) return months * 30;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
