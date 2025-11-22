import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pao_tracker/utils/notification_preferences.dart';
import '../app.dart';
import '../utils/theme_preferences.dart';
import '../utils/csv_exporter.dart';
import '../utils/csv_importer.dart';
import '../data/database_helper.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/product_provider.dart'; // Needed for invalidating provider

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _notificationsEnabled;
  late int _notificationDays;
  final _daysController = TextEditingController();
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _notificationsEnabled =
        await NotificationPreferences.loadNotificationsEnabled();
    _notificationDays = await NotificationPreferences.loadNotificationDays();
    _daysController.text = _notificationDays.toString();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  // Convert ThemeMode to readable string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

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
                      if (context.mounted)
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

  Future<void> _handleExport(BuildContext context) async {
    setState(() => _isExporting = true);

    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      if (products.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No products to export.')));
        return;
      }

      // Fetch categories for export
      final categories = await DatabaseHelper.instance.getAllCategories();

      final csvString = convertProductsToCsv(products, categories);
      final bytes = utf8.encode(csvString);

      // Pick save location
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save your CSV file',
        fileName: 'products_export.csv',
        bytes: bytes,
      );

      if (filePath == null) {
        // User canceled the picker
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export canceled.')));
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported successfully to: $filePath')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    setState(() => _isImporting = true);

    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Get bytes directly
      );

      if (result == null || result.files.isEmpty) {
        // User canceled
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Import canceled.')));
        return;
      }

      final fileBytes = result.files.first.bytes;
      String csvString;
      if (fileBytes != null) {
        csvString = utf8.decode(fileBytes);
      } else {
        // Fallback for some platforms if bytes are null but path exists
        final path = result.files.single.path;
        if (path != null) {
          final file = File(path);
          csvString = await file.readAsString();
        } else {
          throw Exception('Could not read file content.');
        }
      }

      // Fetch categories for import resolution
      final categories = await DatabaseHelper.instance.getAllCategories();

      final products = parseCsv(csvString, categories);

      if (products.isEmpty) {
        throw Exception('No valid products found in CSV.');
      }

      await DatabaseHelper.instance.insertProductsBatch(products);

      // Refresh the provider
      ref.invalidate(productListProvider);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported ${products.length} products.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
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
          _buildSectionHeader('Notifications', textTheme, colorScheme),
          _buildNotificationSettings(context),
          _buildSectionHeader('Data', textTheme, colorScheme),
          _buildSettingsTile(
            context,
            icon: Icons.upload_file_rounded,
            title: _isExporting ? 'Processing...' : 'Export All Products',
            subtitle: 'Save your product list as a CSV file.',
            onTap: _isExporting ? null : () => _handleExport(context),
            trailing: _isExporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context,
            icon: Icons.download_rounded,
            title: _isImporting ? 'Importing...' : 'Import Products',
            subtitle: 'Import from a CSV file.',
            onTap: (_isExporting || _isImporting)
                ? null
                : () => _handleImport(context),
            trailing: _isImporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
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

  Widget _buildNotificationSettings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              'Enable Notifications',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Receive alerts for expiring products',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            value: _notificationsEnabled,
            onChanged: (bool value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              await NotificationPreferences.saveNotificationsEnabled(value);
            },
            secondary: Icon(
              Icons.notifications_active_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (_notificationsEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextFormField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Notify days before expiry',
                  hintText: 'e.g., 7',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  final days = int.tryParse(value);
                  if (days != null) {
                    NotificationPreferences.saveNotificationDays(days);
                  }
                },
              ),
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
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: colorScheme.onSurfaceVariant, size: 28),
        title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}
