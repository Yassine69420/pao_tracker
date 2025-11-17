import 'package:flutter/material.dart';
import '../app.dart';
import '../utils/theme_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Convert ThemeMode to readable string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System Default';
    }
  }

  // Show theme selection dialog
  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            return AlertDialog(
              title: const Text('Choose Theme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ThemeMode.values.map((mode) {
                  return RadioListTile<ThemeMode>(
                    title: Text(_themeModeToString(mode)),
                    value: mode,
                    groupValue: currentMode,
                    onChanged: (value) async {
                      if (value != null) {
                        themeNotifier.value = value;
                        await ThemePreferences.saveThemeMode(value); // persist
                      }
                      Navigator.pop(context); // close dialog
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          _buildSectionHeader('Data', textTheme, colorScheme),
          _buildSettingsTile(
            context,
            icon: Icons.upload_file_rounded,
            title: 'Export All Products',
            subtitle: 'Save your product list as a CSV file.',
            onTap: () => _showComingSoonDialog(context, 'Export'),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.download_rounded,
            title: 'Import Products',
            subtitle: 'Import from a CSV file.',
            onTap: () => _showComingSoonDialog(context, 'Import'),
          ),
          _buildSectionHeader('Appearance', textTheme, colorScheme),
          // Theme selection tile
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              return _buildSettingsTile(
                context,
                icon: Icons.brightness_6_outlined,
                title: 'App Theme',
                subtitle: 'Current: ${_themeModeToString(currentMode)}',
                onTap: () => _showThemeDialog(context),
              );
            },
          ),
          _buildSectionHeader('About', textTheme, colorScheme),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
        ],
      ),
    );
  }

  // Section header
  Widget _buildSectionHeader(
    String title,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: textTheme.titleSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Settings tile
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: colorScheme.onSurfaceVariant, size: 28),
        title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  // Coming soon dialog
  void _showComingSoonDialog(BuildContext context, String feature) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.build_outlined, size: 32, color: colorScheme.primary),
        title: Text('$feature Coming Soon'),
        content: const Text(
          'This feature is currently under development. Stay tuned!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}
