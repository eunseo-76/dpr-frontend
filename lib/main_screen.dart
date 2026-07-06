import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/core/widgets/floating_nav_bar.dart';
import 'package:dpr_frontend/features/home/screens/home_screen.dart';
import 'package:dpr_frontend/features/production/screens/production_screen.dart';
import 'package:dpr_frontend/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;
  String? _role;
  bool _navBarVisible = true;

  bool get _canManageSettings => _role == 'OWNER' || _role == 'MANAGER';

  List<Widget> get _screens => [
    ProductionScreen(
      onGoToSettings: _canManageSettings
          ? () => setState(() => _currentIndex = 2)
          : null,
    ),
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
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              // 생산실적 탭에서 아래로 스크롤하면 메뉴바 숨김, 위로 스크롤하면 다시 표시
              if (_currentIndex != 0) return false;
              if (notification.direction == ScrollDirection.reverse && _navBarVisible) {
                setState(() => _navBarVisible = false);
              } else if (notification.direction == ScrollDirection.forward && !_navBarVisible) {
                setState(() => _navBarVisible = true);
              }
              return false;
            },
            child: _screens[_currentIndex],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              offset: _navBarVisible ? Offset.zero : const Offset(0, 1.3),
              child: FloatingNavBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() {
                  _currentIndex = index;
                  _navBarVisible = true;
                }),
                items: _navItems,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
