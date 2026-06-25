import 'package:dpr_frontend/core/utils/token_storage.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/features/auth/screens/app_info_screen.dart';
import 'package:dpr_frontend/features/auth/screens/edit_profile_screen.dart';
import 'package:dpr_frontend/features/auth/screens/landing_screen.dart';
import 'package:dpr_frontend/features/auth/screens/withdraw_screen.dart';
import 'package:dpr_frontend/core/widgets/name_avatar.dart';
import 'package:flutter/material.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String _name = '';
  String _position = '';
  String _role = '';
  String _companyName = '';
  String? _factoryName;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final results = await Future.wait([
      UserStorage.getName(),
      UserStorage.getPosition(),
      UserStorage.getRole(),
      UserStorage.getCompanyName(),
      UserStorage.getFactoryName(),
    ]);
    if (mounted) {
      setState(() {
        _name = results[0] ?? '';
        _position = results[1] ?? '';
        _role = results[2] ?? '';
        _companyName = results[3] ?? '';
        _factoryName = results[4];
      });
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clearToken();
    await UserStorage.clearUserInfo();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF1E3A5F)),
      title: Text(label, style: TextStyle(color: textColor)),
      trailing: showChevron ? Icon(Icons.chevron_right, color: Colors.grey[400]) : null,
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Divider(height: 0.5, thickness: 0.5, indent: 56, color: Colors.grey[200]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('내 정보'),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 16),
          // 프로필
          Center(child: NameAvatar(name: _name, size: 72, fontSize: 28)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              _position,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          // 소속 정보
          if (_role == 'OWNER' || _factoryName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (_role == 'OWNER') ...[
                    ListTile(
                      leading: Icon(Icons.business_outlined, color: Colors.grey[600]),
                      title: Text('회사', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      subtitle: Text(_companyName, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                    ),
                    if (_factoryName != null) _divider(),
                  ],
                  if (_factoryName != null)
                    ListTile(
                      leading: Icon(Icons.factory_outlined, color: Colors.grey[600]),
                      title: Text('소속', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      subtitle: Text(_factoryName!, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                    ),
                ],
              ),
            ),
          // 메뉴
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _menuTile(
                  icon: Icons.person_outline,
                  label: '회원정보 수정',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _menuTile(
              icon: Icons.info_outline,
              label: '앱 정보',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppInfoScreen()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _menuTile(
                  icon: Icons.logout,
                  label: '로그아웃',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  showChevron: false,
                  onTap: _logout,
                ),
                if (_role != 'OWNER') ...[
                  _divider(),
                  _menuTile(
                    icon: Icons.person_remove_outlined,
                    label: '회원탈퇴',
                    iconColor: Colors.red[300],
                    textColor: Colors.red[300],
                    showChevron: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WithdrawScreen()),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}