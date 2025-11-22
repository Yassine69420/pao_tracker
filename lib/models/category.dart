import 'package:flutter/material.dart';

class Category {
  static const String tableName = 'categories';
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colIcon = 'icon_codepoint';
  static const String colColor = 'color_value';

  static const String createTable =
      '''
CREATE TABLE $tableName (
  $colId TEXT PRIMARY KEY,
  $colName TEXT NOT NULL,
  $colIcon INTEGER NOT NULL,
  $colColor INTEGER NOT NULL
);
''';

  final String id;
  final String name;
  final int iconCodepoint;
  final int colorValue;

  const Category({
    required this.id,
    required this.name,
    required this.iconCodepoint,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCodepoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, Object?> toMap() {
    return {
      colId: id,
      colName: name,
      colIcon: iconCodepoint,
      colColor: colorValue,
    };
  }

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map[colId] as String,
      name: map[colName] as String,
      iconCodepoint: map[colIcon] as int,
      colorValue: map[colColor] as int,
    );
  }
}
