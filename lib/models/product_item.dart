import 'dart:convert';

/// Model representing a product item with PAO and expiry information.
class ProductItem {
  // Database table and column names
  static const String tableName = 'product_items';
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colBrand = 'brand';
  static const String colOpenedDate = 'opened_date';
  static const String colShelfLifeDays = 'shelf_life_days';
  static const String colExpiryDate = 'expiry_date';
  // --- NEW FIELD ---
  static const String colUnopenedExpiryDate = 'unopened_expiry_date';
  static const String colIsOpened = 'is_opened';
  static const String colLabel = 'label';
  static const String colPhotoPath = 'photo_path';
  static const String colFavorite = 'favorite';
  static const String colNotes = 'notes';

  static const String createTable = '''
CREATE TABLE $tableName (
  $colId TEXT PRIMARY KEY,
  $colName TEXT NOT NULL,
  $colBrand TEXT,
  $colOpenedDate INTEGER NOT NULL,
  $colShelfLifeDays INTEGER NOT NULL,
  $colExpiryDate INTEGER NOT NULL,
  $colUnopenedExpiryDate INTEGER, 
  $colIsOpened INTEGER NOT NULL,
  $colLabel TEXT NOT NULL,
  $colPhotoPath TEXT,
  $colFavorite INTEGER NOT NULL,
  $colNotes TEXT
);
''';

  final String id;
  final String name;
  final String? brand;
  final DateTime openedDate;
  final int shelfLifeDays;
  final DateTime expiryDate;
  final DateTime? unopenedExpiryDate; // --- NEW FIELD ---
  final bool isOpened;
  final String label;
  final String? photoPath;
  final bool favorite;
  final List<String>? notes;

  ProductItem({
    required this.id,
    required this.name,
    this.brand,
    required this.openedDate,
    required this.shelfLifeDays,
    required this.expiryDate,
    this.unopenedExpiryDate, // --- NEW FIELD ---
    this.isOpened = false,
    required this.label,
    this.photoPath,
    this.favorite = false,
    this.notes,
  });

  int get remainingDays {
    final diff = expiryDate.difference(DateTime.now()).inDays;
    return diff;
  }

  Map<String, Object?> toMap() {
    return {
      colId: id,
      colName: name,
      colBrand: brand,
      colOpenedDate: openedDate.millisecondsSinceEpoch,
      colShelfLifeDays: shelfLifeDays,
      colExpiryDate: expiryDate.millisecondsSinceEpoch,
      colUnopenedExpiryDate:
          unopenedExpiryDate?.millisecondsSinceEpoch, // --- NEW FIELD ---
      colIsOpened: isOpened ? 1 : 0,
      colLabel: label,
      colPhotoPath: photoPath,
      colFavorite: favorite ? 1 : 0,
      colNotes: notes == null ? null : json.encode(notes),
    };
  }

  factory ProductItem.fromMap(Map<String, Object?> map) {
    DateTime parseDate(dynamic raw) {
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is String) return DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
      throw FormatException('Unsupported date type: ${raw.runtimeType}');
    }

    // --- NEW HELPER ---
    DateTime? parseDateNullable(dynamic raw) {
      if (raw == null) return null;
      return parseDate(raw);
    }

    bool parseBool(dynamic raw) {
      if (raw is int) return raw != 0;
      if (raw is String) return int.parse(raw) != 0;
      if (raw is bool) return raw;
      return false;
    }

    List<String>? parseNotes(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) {
        try {
          final decoded = json.decode(raw);
          if (decoded is List) return decoded.map((e) => e?.toString() ?? '').toList();
          return [raw];
        } catch (_) {
          return [raw];
        }
      }
      return [raw.toString()];
    }

    return ProductItem(
      id: map[colId] as String,
      name: map[colName] as String,
      brand: map[colBrand] as String?,
      openedDate: parseDate(map[colOpenedDate]),
      shelfLifeDays: (map[colShelfLifeDays] is int)
          ? map[colShelfLifeDays] as int
          : int.parse(map[colShelfLifeDays].toString()),
      expiryDate: parseDate(map[colExpiryDate]),
      unopenedExpiryDate:
          parseDateNullable(map[colUnopenedExpiryDate]), // --- NEW FIELD ---
      isOpened: parseBool(map[colIsOpened]),
      label: map[colLabel] as String,
      photoPath: map[colPhotoPath] as String?,
      favorite: parseBool(map[colFavorite]),
      notes: parseNotes(map[colNotes]),
    );
  }

  ProductItem copyWith({
    String? id,
    String? name,
    Object? brand = _Undefined,
    DateTime? openedDate,
    int? shelfLifeDays,
    DateTime? expiryDate,
    Object? unopenedExpiryDate = _Undefined, // --- NEW FIELD ---
    bool? isOpened,
    String? label,
    Object? photoPath = _Undefined,
    bool? favorite,
    Object? notes = _Undefined,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand == _Undefined ? this.brand : brand as String?,
      openedDate: openedDate ?? this.openedDate,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      expiryDate: expiryDate ?? this.expiryDate,
      unopenedExpiryDate: unopenedExpiryDate == _Undefined
          ? this.unopenedExpiryDate
          : unopenedExpiryDate as DateTime?, // --- NEW FIELD ---
      isOpened: isOpened ?? this.isOpened,
      label: label ?? this.label,
      photoPath: photoPath == _Undefined ? this.photoPath : photoPath as String?,
      favorite: favorite ?? this.favorite,
      notes: notes == _Undefined ? this.notes : notes as List<String>?,
    );
  }

  @override
  String toString() {
    return 'ProductItem(id: $id, name: $name, brand: $brand, openedDate: $openedDate, shelfLifeDays: $shelfLifeDays, expiryDate: $expiryDate, unopenedExpiryDate: $unopenedExpiryDate, isOpened: $isOpened, label: $label, photoPath: $photoPath, favorite: $favorite, notes: $notes)';
  }
}

class _Undefined {
  const _Undefined();
}