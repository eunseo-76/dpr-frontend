import 'package:dpr_frontend/features/home/screens/home_screen.dart';
import 'package:dpr_frontend/features/production/screens/production_screen.dart';
import 'package:dpr_frontend/features/utility/screens/utility_screen.dart';
import 'package:dpr_frontend/features/wip/screens/wip_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [HomeScreen(), ProductionScreen(), WipScreen(), UtilityScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E3A5F),
        unselectedItemColor: Colors.grey[500],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: '생산실적',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers),
            label: '재공현황',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.electric_bolt),
            label: '전기&용수',
          ),
        ],
      ),
    );
  }
}
