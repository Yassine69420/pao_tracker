import 'dart:convert';

/// Model representing a product item with PAO information.
class ProductItem {
  // Database table and column names
  static const String tableName = 'product_items';
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colBrand = 'brand';
  static const String colOpenedDate = 'opened_date';
  static const String colShelfLifeDays = 'shelf_life_days';
  static const String colLabel = 'label';
  static const String colPhotoPath = 'photo_path';
  static const String colFavorite = 'favorite';
  static const String colNotes = 'notes';

  static const String createTable =
      '''
CREATE TABLE $tableName (
  $colId TEXT PRIMARY KEY,
  $colName TEXT NOT NULL,
  $colBrand TEXT,
  $colOpenedDate INTEGER NOT NULL,
  $colShelfLifeDays INTEGER NOT NULL,
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
    required this.label,
    this.photoPath,
    this.favorite = false,
    this.notes,
  });

  DateTime get expiryDate => openedDate.add(Duration(days: shelfLifeDays));

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
      colLabel: label,
      colPhotoPath: photoPath,
      colFavorite: favorite ? 1 : 0,
      colNotes: notes == null ? null : json.encode(notes),
    };
  }

  factory ProductItem.fromMap(Map<String, Object?> map) {
    final openedRaw = map[colOpenedDate];
    final shelfRaw = map[colShelfLifeDays];
    final favoriteRaw = map[colFavorite];
    final notesRaw = map[colNotes];

    DateTime opened;
    if (openedRaw is int) {
      opened = DateTime.fromMillisecondsSinceEpoch(openedRaw);
    } else if (openedRaw is String) {
      opened = DateTime.fromMillisecondsSinceEpoch(int.parse(openedRaw));
    } else {
      throw FormatException(
        'Unsupported opened_date type: ${openedRaw.runtimeType}',
      );
    }

    int shelfDays;
    if (shelfRaw is int) {
      shelfDays = shelfRaw;
    } else if (shelfRaw is String) {
      shelfDays = int.parse(shelfRaw);
    } else {
      throw FormatException(
        'Unsupported shelf_life_days type: ${shelfRaw.runtimeType}',
      );
    }

    bool fav;
    if (favoriteRaw is int) {
      fav = favoriteRaw != 0;
    } else if (favoriteRaw is String) {
      fav = int.parse(favoriteRaw) != 0;
    } else if (favoriteRaw is bool) {
      fav = favoriteRaw;
    } else {
      fav = false;
    }

    List<String>? parsedNotes;
    if (notesRaw == null) {
      parsedNotes = null;
    } else if (notesRaw is String) {
      try {
        final dynamic decoded = json.decode(notesRaw);
        if (decoded is List) {
          parsedNotes = decoded
              .map((e) => e?.toString() ?? '')
              .cast<String>()
              .toList();
        } else {
          parsedNotes = [notesRaw];
        }
      } catch (_) {
        parsedNotes = [notesRaw];
      }
    } else {
      parsedNotes = [notesRaw.toString()];
    }

    return ProductItem(
      id: (map[colId] as String),
      name: (map[colName] as String),
      brand: map[colBrand] as String?,
      openedDate: opened,
      shelfLifeDays: shelfDays,
      label: (map[colLabel] as String),
      photoPath: map[colPhotoPath] as String?,
      favorite: fav,
      notes: parsedNotes,
    );
  }

  /// FIXED: Proper handling of nullable fields
  /// Use a special _Undefined class to distinguish between "not provided" and "explicitly null"
  ProductItem copyWith({
    String? id,
    String? name,
    Object? brand =
        _Undefined, // Changed to Object to accept both String? and _Undefined
    DateTime? openedDate,
    int? shelfLifeDays,
    String? label,
    Object? photoPath = _Undefined, // Changed to Object
    bool? favorite,
    Object? notes = _Undefined, // Changed to Object
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand == _Undefined ? this.brand : brand as String?,
      openedDate: openedDate ?? this.openedDate,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      label: label ?? this.label,
      photoPath: photoPath == _Undefined
          ? this.photoPath
          : photoPath as String?,
      favorite: favorite ?? this.favorite,
      notes: notes == _Undefined ? this.notes : notes as List<String>?,
    );
  }

  @override
  String toString() {
    return 'ProductItem(id: $id, name: $name, brand: $brand, openedDate: $openedDate, shelfLifeDays: $shelfLifeDays, label: $label, photoPath: $photoPath, favorite: $favorite, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductItem &&
        other.id == id &&
        other.name == name &&
        other.brand == brand &&
        other.openedDate == openedDate &&
        other.shelfLifeDays == shelfLifeDays &&
        other.label == label &&
        other.photoPath == photoPath &&
        other.favorite == favorite &&
        _listEquals(other.notes, notes);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      brand,
      openedDate,
      shelfLifeDays,
      label,
      photoPath,
      favorite,
      notes == null ? 0 : Object.hashAll(notes!),
    );
  }

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Sentinel class to distinguish "not provided" from "explicitly null"
class _Undefined {
  const _Undefined();
}
