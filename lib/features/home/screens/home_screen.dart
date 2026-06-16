import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/features/auth/screens/my_page_screen.dart';
import 'package:dpr_frontend/features/production/screens/production_screen.dart';
import 'package:dpr_frontend/features/settings/screens/settings_screen.dart';
import 'package:dpr_frontend/features/utility/screens/utility_screen.dart';
import 'package:dpr_frontend/features/wip/screens/wip_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = '';
  String _position = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await UserStorage.getName();
    final position = await UserStorage.getPosition();
    if (mounted) {
      setState(() {
        _name = name ?? '';
        _position = position ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyPageScreen()),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A5F),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _name.isNotEmpty ? _name[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _position,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final items = [
      (Icons.precision_manufacturing, '생산실적', const ProductionScreen()),
      (Icons.layers, '재공현황', const WipScreen()),
      (Icons.electric_bolt, '전기&용수', const UtilityScreen()),
      (Icons.settings, '설정', const SettingsScreen()),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, label, screen) = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(icon, color: const Color(0xFF1E3A5F)),
                title: Text(label),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => screen),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}