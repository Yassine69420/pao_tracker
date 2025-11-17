import 'package:flutter/material.dart';
import 'package:pao_tracker/screens/home_screen.dart';
import 'package:pao_tracker/screens/settings_screen.dart';
import 'package:pao_tracker/screens/statistics_screen.dart';
// No longer need to import AppColors here
// import 'package:pao_tracker/utils/colors.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Assuming these screens exist at the paths.
  // If not, you might need to create placeholder widgets.
  final List<Widget> _screens = const [
    HomeScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme and color scheme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true, // Allows BottomNavigationBar to float
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // UPDATED: Use theme-aware color for the container.
          // Using surfaceVariant provides a nice contrast from the main scaffold.
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              // UPDATED: Use the theme's shadow color for a consistent look
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabSelected,
            // UPDATED: Use the same theme-aware color for the bar
            backgroundColor: colorScheme.surfaceVariant,
            type: BottomNavigationBarType.fixed,
            // UPDATED: Use the theme's primary color
            selectedItemColor: colorScheme.primary,
            // UPDATED: Use the theme's 'onSurfaceVariant' color
            unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
