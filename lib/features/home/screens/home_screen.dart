import 'package:dpr_frontend/core/models/factory_summary.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/core/widgets/factory_tag.dart';
import 'package:dpr_frontend/core/widgets/menu_card.dart';
import 'package:dpr_frontend/core/widgets/name_avatar.dart';
import 'package:dpr_frontend/features/auth/screens/my_page_screen.dart';
import 'package:dpr_frontend/features/settings/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _name = '';
  String _position = '';
  String _role = '';
  List<FactorySummary> _factories = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await UserStorage.getName();
    final position = await UserStorage.getPosition();
    final role = await UserStorage.getRole();
    final factories = await UserStorage.getFactories();
    if (mounted) {
      setState(() {
        _name = name ?? '';
        _position = position ?? '';
        _role = role ?? '';
        _factories = factories;
      });
    }
  }

  bool get _isAdmin => _role == 'OWNER' || _role == 'MANAGER';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
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
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyPageScreen()),
      ),
      child: Row(
        children: [
          NameAvatar(name: _name, size: 48, fontSize: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_role != 'OWNER')
                      ..._factories.map(
                        (f) => FactoryTag(label: f.factoryName),
                      ),
                  ],
                ),
                Text(
                  _position,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final items = [
      MenuItem(
        icon: Icons.precision_manufacturing,
        label: '생산실적',
        onTap: () => widget.onTabChange(0),
      ),
      if (_isAdmin)
        MenuItem(
          icon: Icons.settings,
          label: '설정',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
    ];

    return MenuCard(items: items);
  }
}