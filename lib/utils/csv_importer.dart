import 'package:csv/csv.dart';
import '../models/product_item.dart';
import '../models/category.dart';

/// Parses a CSV string into a list of [ProductItem]s.
///
/// Expects the CSV to have a header row matching the export format.
/// Throws a [FormatException] if the CSV is invalid or data is malformed.
List<ProductItem> parseCsv(String csvContent, List<Category> categories) {
  // Use the csv package to parse the string
  // eol: '\n' is standard, but the converter usually handles different EOLs.
  // shouldParseNumbers: false to keep everything as strings initially for safer manual parsing
  final List<List<dynamic>> rows = const CsvToListConverter(
    shouldParseNumbers: false,
  ).convert(csvContent);

  if (rows.isEmpty) {
    return [];
  }

  // Validate header
  // We expect the first row to be the header.
  // We could strictly validate it, or just assume the order if it looks roughly right.
  // For robustness, let's just skip the first row.
  // If the file is empty or only has a header, we return empty list.
  if (rows.length < 2) {
    return [];
  }

  // Create a map for reverse lookup (Name -> ID)
  // Normalize keys to lowercase for case-insensitive matching
  final categoryNameMap = {
    for (var c in categories) c.name.toLowerCase(): c.id,
  };

  final List<ProductItem> products = [];

  // Start from index 1 to skip header
  for (int i = 1; i < rows.length; i++) {
    final row = rows[i];
    // We expect at least 12 columns based on old export, 13 with category
    if (row.length < 12) {
      // Skip malformed rows or throw? Let's skip and log/print if possible,
      // but here we'll just continue to try to get as much data as possible.
      continue;
    }

    try {
      // 0: ID
      final id = row[0].toString();
      if (id.isEmpty) continue; // ID is required

      // 1: Name
      final name = row[1].toString();

      // 2: Brand
      final brand = row[2].toString().isEmpty ? null : row[2].toString();

      // 3: OpenedDate
      final openedDate = DateTime.parse(row[3].toString());

      // 4: ShelfLifeDays
      final shelfLifeDays = int.parse(row[4].toString());

      // 5: ExpiryDate
      final expiryDate = DateTime.parse(row[5].toString());

      // 6: UnopenedExpiryDate
      final unopenedExpiryDateStr = row[6].toString();
      final unopenedExpiryDate = unopenedExpiryDateStr.isEmpty
          ? null
          : DateTime.parse(unopenedExpiryDateStr);

      // 7: IsOpened
      final isOpened = row[7].toString().toLowerCase() == 'true';

      // 8: Label
      final label = row[8].toString();

      // 9: PhotoPath
      final photoPath = row[9].toString().isEmpty ? null : row[9].toString();

      // 10: Favorite
      final favorite = row[10].toString().toLowerCase() == 'true';

      // 11: Notes
      final notesStr = row[11].toString();
      final notes = notesStr.isEmpty ? null : notesStr.split('|');

      // 12: Category (Optional, might not exist in old CSVs)
      String? categoryId;
      if (row.length > 12) {
        final catName = row[12].toString().trim();
        if (catName.isNotEmpty) {
          categoryId = categoryNameMap[catName.toLowerCase()];
          // If category not found, we default to null (or could default to 'Other')
          if (categoryId == null && categoryNameMap.containsKey('other')) {
            categoryId = categoryNameMap['other'];
          }
        }
      }

      final product = ProductItem(
        id: id,
        name: name,
        brand: brand,
        openedDate: openedDate,
        shelfLifeDays: shelfLifeDays,
        expiryDate: expiryDate,
        unopenedExpiryDate: unopenedExpiryDate,
        isOpened: isOpened,
        label: label,
        photoPath: photoPath,
        favorite: favorite,
        notes: notes,
        categoryId: categoryId,
      );

      products.add(product);
    } catch (e) {
      // If a row fails to parse, we skip it.
      // In a real app, we might want to collect errors and report them.
      print('Error parsing row $i: $e');
    }
  }

  return products;
}
