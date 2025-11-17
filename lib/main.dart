import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database_helper.dart';
import 'app.dart';
// --- MODIFICATION ---


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseHelper.instance.init();
    print('✅ Database successfully initialized.');
  } catch (e) {
    print('❌ Database initialization failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

