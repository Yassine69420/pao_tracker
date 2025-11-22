import 'package:flutter/material.dart';
import 'screens/widgets/main_nav_screen.dart';
import 'utils/colors.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          title: 'PAO Tracker',
          themeMode: currentMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const MainNavScreen(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceVariant: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimaryContainer,
        secondary: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiaryContainer,
        onTertiary: AppColors.onTertiaryContainer,
        error: AppColors.errorContainer,
        onError: AppColors.onErrorContainer,
        surface: const Color(0xFF1E1E1E),
        onSurface: Colors.white70,
        surfaceVariant: const Color(0xFF2C2C2C),
        onSurfaceVariant: Colors.white38,
        outline: Colors.grey,
        outlineVariant: Colors.grey.shade800,
      ),
    );
  }
}
