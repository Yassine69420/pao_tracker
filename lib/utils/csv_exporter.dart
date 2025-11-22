import 'package:csv/csv.dart';
import '../models/product_item.dart';
import '../models/category.dart';

String convertProductsToCsv(
  List<ProductItem> products,
  List<Category> categories,
) {
  final header = [
    'ID',
    'Name',
    'Brand',
    'OpenedDate',
    'ShelfLifeDays',
    'ExpiryDate',
    'UnopenedExpiryDate',
    'IsOpened',
    'Label',
    'PhotoPath',
    'Favorite',
    'Notes',
    'Category', // New column
  ];

  // Create a map for quick lookup
  final categoryMap = {for (var c in categories) c.id: c.name};

  final rows = products.map((p) {
    final row = p.toCsvRow();
    // Resolve category name
    final catName = p.categoryId != null
        ? (categoryMap[p.categoryId] ?? '')
        : '';
    return [...row, catName];
  }).toList();

  final csvData = [header, ...rows];
  return const ListToCsvConverter().convert(csvData);
}
