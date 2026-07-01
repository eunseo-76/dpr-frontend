import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/core/widgets/floating_nav_bar.dart';
import 'package:dpr_frontend/features/home/screens/home_screen.dart';
import 'package:dpr_frontend/features/production/screens/production_screen.dart';
import 'package:dpr_frontend/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  String? _role;

  bool get _canManageSettings => _role == 'OWNER' || _role == 'MANAGER';

  List<Widget> get _screens => [
    const ProductionScreen(),
    HomeScreen(onTabChange: (index) => setState(() => _currentIndex = index)),
    if (_canManageSettings) const SettingsScreen(),
  ];

  List<FloatingNavItem> get _navItems => [
    const FloatingNavItem(icon: Icons.precision_manufacturing, label: '생산실적'),
    const FloatingNavItem(icon: Icons.home, label: '홈'),
    if (_canManageSettings) const FloatingNavItem(icon: Icons.settings, label: '설정'),
  ];


  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await UserStorage.getRole();
    if (mounted) setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingNavBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: _navItems,
            ),
          ),
        ],
      ),
    );
  }
}
