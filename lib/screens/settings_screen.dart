import 'package:flutter/material.dart';
import 'package:pao_tracker/utils/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        // Add padding to avoid the bottom navigation bar
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          _buildSectionHeader('Data', context),
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
          _buildSectionHeader('Appearance', context),
          _buildSettingsTile(
            context,
            icon: Icons.brightness_6_outlined,
            title: 'App Theme',
            subtitle: 'Current: System Default',
            onTap: () => _showComingSoonDialog(context, 'Theme Switching'),
          ),
          _buildSectionHeader('About', context),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: 'App Version',
            subtitle: '1.0.0', // Just info, no tap
            onTap: null, // No action
          ),
        ],
      ),
    );
  }

  /// Helper for building styled section headers
  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  /// Helper for building styled ListTiles inside a Card
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      // Use a subtle background color
      color: AppColors.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        onTap: onTap,
        trailing: onTap != null
            ? Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Helper to show a "Coming Soon" dialog
  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.build_outlined, size: 32),
        title: Text('$feature Coming Soon'),
        content:
            const Text('This feature is currently under development. Stay tuned!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}