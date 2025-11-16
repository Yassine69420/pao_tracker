import 'package:flutter/material.dart';
import 'package:pao_tracker/screens/home_screen.dart';
import 'package:pao_tracker/screens/settings_screen.dart';
import 'package:pao_tracker/screens/statistics_screen.dart';
import 'package:pao_tracker/utils/colors.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

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
    return Scaffold(
      extendBody: true, // Allows BottomNavigationBar to float
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
            backgroundColor: AppColors.surface,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.onSurfaceVariant.withOpacity(0.7),
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
