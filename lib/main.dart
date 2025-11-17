import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database_helper.dart';
import 'app.dart';
import 'utils/theme_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseHelper.instance.init();
    print('✅ Database successfully initialized.');
  } catch (e) {
    print('❌ Database initialization failed: $e');
  }

  // Load saved theme from SharedPreferences
  final savedTheme = await ThemePreferences.loadThemeMode();
  themeNotifier.value = savedTheme;

  runApp(const ProviderScope(child: MyApp()));
}
