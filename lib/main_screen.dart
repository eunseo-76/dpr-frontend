import 'package:fprs_frontend/core/utils/user_storage.dart';
import 'package:fprs_frontend/core/widgets/floating_nav_bar.dart';
import 'package:fprs_frontend/features/home/screens/home_screen.dart';
import 'package:fprs_frontend/features/production/screens/production_screen.dart';
import 'package:fprs_frontend/features/production_comparison/screens/production_comparison_screen.dart';
import 'package:fprs_frontend/features/settings/screens/settings_screen.dart';
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

  bool get _canManageSettings => UserStorage.isAdmin(_role);
  bool get _canViewComparison => _role == 'OWNER';

  List<Widget> get _screens => [
    ProductionScreen(
      isActive: _currentIndex == 0,
      onGoToSettings: _canManageSettings
          ? () => setState(() => _currentIndex = _canViewComparison ? 3 : 2)
          : null,
    ),
    HomeScreen(onTabChange: (index) => setState(() => _currentIndex = index)),
    if (_canViewComparison) ProductionComparisonScreen(isActive: _currentIndex == 2),
    if (_canManageSettings) const SettingsScreen(),
  ];

  List<FloatingNavItem> get _navItems => [
    const FloatingNavItem(icon: Icons.precision_manufacturing, label: '생산실적'),
    const FloatingNavItem(icon: Icons.home, label: '홈'),
    if (_canViewComparison)
      const FloatingNavItem(icon: Icons.compare_arrows_rounded, label: '실적비교'),
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
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              offset: _navBarVisible ? Offset.zero : const Offset(0, 1.3),
              child: SafeArea(
                top: false,
                // 바깥 Positioned가 이미 bottom 인셋만큼 밀어올렸으니, 여기서
                // 또 적용하면 이중으로 밀려 올라간다 (Android 15 엣지투엣지 강제 이후
                // padding.bottom이 0이 아니게 되면서 드러난 문제, 2026-09-18).
                bottom: false,
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
          ),
        ],
      ),
    );
  }
}
