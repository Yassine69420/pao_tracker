import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_item.dart';
import '../models/category.dart';
import 'package:pao_tracker/screens/widgets/photo_picker.dart';
import 'package:pao_tracker/screens/widgets/pao_options.dart';
import 'package:pao_tracker/screens/widgets/favorite_button.dart';

import '../providers/product_provider.dart';
import '../data/database_helper.dart';

import '../app.dart';

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
  DateTime? _unopenedExpiryDate; // New field for unopened expiry
  String? _photoPath;
  bool _favorite = false;
  bool _isOpened = false;
  bool _isLoading = false;

  // Keep last selected PAO in months for convenience
  int? _selectedPaoMonths;

  List<Category> _categories = [];
  String? _selectedCategoryId;

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
      _isOpened = widget.product!.isOpened;

      // --- FIXED: Always set unopened expiry date from existing product ---
      _unopenedExpiryDate = widget.product!.expiryDate;

      // Try to parse label like "12M"
      final match = RegExp(
        r"(\d+)\s*M",
        caseSensitive: false,
      ).firstMatch(widget.product!.label);
      if (match != null) {
        _selectedPaoMonths = int.tryParse(match.group(1)!);
      }
      _selectedCategoryId = widget.product!.categoryId;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        // If creating a new product and no category selected, maybe default to 'Other' or null?
        // For now, we leave it null unless user selects one.
      });
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
    // --- NEW: Get colorScheme from Theme ---
    final colorScheme = Theme.of(context).colorScheme;

    // --- NEW: Listen to theme changes ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        // --- End New ---

        return Scaffold(
          // --- UPDATED: Use theme color ---
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Product' : 'Add Product'),
            backgroundColor: colorScheme.surface, // theme color
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
                    // --- UPDATED: Use theme color ---
                    fillColor: colorScheme.surfaceVariant,
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

                // Brand field
                TextFormField(
                  controller: _brandController,
                  decoration: InputDecoration(
                    label: const Text('Brand (Optional)'),
                    prefixIcon: const Icon(Icons.business_outlined),
                    filled: true,
                    // --- UPDATED: Use theme color ---
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    label: const Text('Category'),
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(cat.icon, size: 20, color: cat.color),
                          const SizedBox(width: 12),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) => null, // Optional
                ),
                const SizedBox(height: 20),

                // --- NEW: Unopened Expiry Date Field ---
                Text(
                  "Expiry Date (Unopened)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _selectUnopenedExpiryDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined),
                        const SizedBox(width: 12),
                        Text(
                          _unopenedExpiryDate == null
                              ? 'Select date'
                              : _formatDate(_unopenedExpiryDate!),
                          style: TextStyle(
                            fontSize: 16,
                            color: _unopenedExpiryDate == null
                                ? colorScheme
                                      .error // Highlight if not selected
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // --- End of New Field ---

                // Is Opened Checkbox
                // ---
                // --- OPTIMIZATION: Replaced AnimatedContainer with Container ---
                // --- Removed 'duration' and 'boxShadow' for better performance ---
                // ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isOpened
                        // --- UPDATED: Use theme color ---
                        ? colorScheme.secondary.withOpacity(0.1)
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    // --- REMOVED: boxShadow for performance ---
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      // --- UPDATED: Use theme color ---
                      unselectedWidgetColor: colorScheme.onSurfaceVariant,
                      checkboxTheme: CheckboxThemeData(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            // --- UPDATED: Use theme color ---
                            return colorScheme.secondary; // checked color
                          }
                          // --- UPDATED: Use theme color ---
                          return colorScheme
                              .onSurfaceVariant; // unchecked color
                        }),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _isOpened,
                      onChanged: (value) =>
                          setState(() => _isOpened = value ?? false),
                      title: const Text(
                        'Product is opened',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Check if you\'ve already started using this product',
                        // --- UPDATED: Use theme color ---
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ),
                ),

                // Show opened date and PAO fields only if product is opened
                if (_isOpened) ...[
                  const SizedBox(height: 20),

                  // Label for opened date
                  const Text(
                    "Opened Date",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  // Opened date field
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _selectOpenedDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        // --- UPDATED: Use theme color ---
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        // --- UPDATED: Use theme color ---
                        border: Border.all(color: colorScheme.outlineVariant),
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

                  const SizedBox(height: 12),

                  // PAO options as segmented buttons + editable input
                  PAOOptions(
                    valuesInMonths: const [
                      1,
                      2,
                      3,
                      4,
                      6,
                      9,
                      12,
                      18,
                      24,
                      36,
                      48,
                      60,
                      72,
                      84,
                      96,
                    ],
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
                      // --- UPDATED: Use theme color ---
                      fillColor: colorScheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return null; // It's optional, so no error if empty
                      }
                      // If not empty, validate the format
                      final parsed = _parsePAOLabel(value);
                      if (parsed == null) {
                        return 'Invalid format. Use 6M, 12M, etc.';
                      }
                      return null; // Valid format
                    },
                  ),
                ],

                const SizedBox(height: 12),

                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    label: const Text('Notes (Optional)'),
                    hintText: 'Add any additional notes\nOne note per line',
                    prefixIcon: const Icon(Icons.note_outlined),
                    alignLabelWithHint: true,
                    filled: true,
                    // --- UPDATED: Use theme color ---
                    fillColor: colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                const SizedBox(height: 16),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveProduct,
                    style: FilledButton.styleFrom(
                      // --- UPDATED: Use theme color ---
                      backgroundColor: colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              // --- UPDATED: Use theme color ---
                              color: colorScheme.onSecondary,
                            ),
                          )
                        : Text(
                            isEditing ? 'Update Product' : 'Add Product',
                            style: TextStyle(
                              fontSize: 16,
                              // --- UPDATED: Use theme color ---
                              color: colorScheme.onSecondary,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // Renamed from _selectDate to be more specific
  Future<void> _selectOpenedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _openedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // Can't open a product in the future
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );

    if (picked != null) setState(() => _openedDate = picked);
  }

  // --- NEW: Date Picker for Unopened Expiry ---
  Future<void> _selectUnopenedExpiryDate() async {
    final now = DateTime.now();

    // Allow a reasonable range in the past so previously saved expiry dates (even if past)
    // are still selectable when editing an existing product.
    final firstDate = DateTime(2000);
    final lastDate = DateTime(now.year + 10);

    // Use stored value if present; otherwise default to today.
    DateTime initial = _unopenedExpiryDate ?? now;

    // Clamp initial so it's within firstDate..lastDate (required by showDatePicker)
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child!),
    );

    if (picked != null) {
      setState(() => _unopenedExpiryDate = picked);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // --- NEW: Get colorScheme for error snackbar ---
    final colorScheme = Theme.of(context).colorScheme;

    int shelfLifeDays = 0;
    DateTime expiryDate;
    final paoLabel = _labelController.text.trim(); // Get the label

    if (_unopenedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an expiry date'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isOpened) {
      final parsedDays = _parsePAOLabel(paoLabel); // Try to parse it

      if (parsedDays != null) {
        // --- Case 1: Product is OPENED and has a VALID PAO ---
        shelfLifeDays = parsedDays;
        DateTime paoExpiryDate = _openedDate.add(Duration(days: shelfLifeDays));

        // Check against unopened expiry
        // If an unopened expiry date exists and it's SOONER than the PAO expiry, use it instead.
        if (_unopenedExpiryDate != null &&
            _unopenedExpiryDate!.isBefore(paoExpiryDate)) {
          expiryDate = _unopenedExpiryDate!;
        } else {
          expiryDate = paoExpiryDate;
        }
      } else {
        // --- Case 2: Product is OPENED but has NO PAO ---
        // Use the unopened expiry date. If that's null, default to openedDate (original logic)
        shelfLifeDays = 0;
        expiryDate = _unopenedExpiryDate ?? _openedDate;
      }
    } else {
      // --- Case 3: Product is NOT OPENED ---
      // Use the unopened expiry date. If that's null, default to openedDate (original logic)
      shelfLifeDays = 0;
      expiryDate = _unopenedExpiryDate ?? _openedDate;
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
          expiryDate: expiryDate, // This now holds the correct expiry
          isOpened: _isOpened,
          label: _isOpened ? paoLabel : '', // Save the actual label
          photoPath: _photoPath,
          favorite: _favorite,
          notes: notes.isEmpty ? null : notes,
          categoryId: _selectedCategoryId,
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
          expiryDate: expiryDate, // This now holds the correct expiry
          isOpened: _isOpened,
          label: _isOpened ? paoLabel : '', // Save the actual label
          photoPath: _photoPath,
          favorite: _favorite,
          notes: notes.isEmpty ? null : notes,
          categoryId: _selectedCategoryId,
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
            // --- UPDATED: Use theme color ---
            backgroundColor: colorScheme.error,
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
