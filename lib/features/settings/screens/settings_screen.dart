import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/models/field_config.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/core/widgets/menu_card.dart';
import 'package:dpr_frontend/features/settings/screens/factory_mapping_screen.dart';
import 'package:dpr_frontend/features/settings/screens/master_data_manage_screen.dart';
import 'package:dpr_frontend/features/settings/screens/invitation_manage_screen.dart';
import 'package:dpr_frontend/features/settings/screens/unit_price_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await UserStorage.getRole();
    if (mounted) setState(() => _role = role);
  }

  bool get _canManageInvitations =>
      _role == 'OWNER' || _role == 'MANAGER';

  void _openManageScreen(
    BuildContext context, {
    required String title,
    required String endpoint,
    required String idKey,
    required List<FieldConfig> fields,
    bool showAvatar = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MasterDataManageScreen(
          title: title,
          service: MasterDataService(endpoint: endpoint, idKey: idKey),
          fields: fields,
          showAvatar: showAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const detailFields = [
      FieldConfig(key: 'name', label: '이름', required: true),
      FieldConfig(key: 'nickname', label: '별칭'),
      FieldConfig(key: 'address', label: '주소'),
      FieldConfig(key: 'email', label: '이메일'),
      FieldConfig(key: 'phone', label: '전화번호'),
    ];

    const simpleFields = [
      FieldConfig(key: 'name', label: '이름', required: true),
      FieldConfig(key: 'nickname', label: '별칭'),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top + kToolbarHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey[100]!],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFF0F4),
                border: Border(top: BorderSide(color: Color(0xFFB0B8C8), width: 2)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment(0, -0.95),
                  colors: [Color(0xFFDFE4F0), Color(0xFFEFF0F4)],
                ),
              ),
              child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        children: [
          MenuCard(
            items: [
              MenuItem(
                icon: Icons.factory,
                label: '공장 관리',
                onTap: () => _openManageScreen(
                  context,
                  title: '공장 관리',
                  endpoint: ApiConstants.factory_,
                  idKey: 'factoryId',
                  fields: detailFields,
                  showAvatar: true,
                ),
              ),
              MenuItem(
                icon: Icons.precision_manufacturing,
                label: '공정 관리',
                onTap: () => _openManageScreen(
                  context,
                  title: '공정 관리',
                  endpoint: ApiConstants.process,
                  idKey: 'processId',
                  fields: simpleFields,
                ),
              ),
              MenuItem(
                icon: Icons.straighten,
                label: '단위 관리',
                onTap: () => _openManageScreen(
                  context,
                  title: '단위 관리',
                  endpoint: ApiConstants.unit,
                  idKey: 'unitId',
                  fields: simpleFields,
                ),
              ),
              MenuItem(
                icon: Icons.business,
                label: '업체 관리',
                onTap: () => _openManageScreen(
                  context,
                  title: '업체 관리',
                  endpoint: ApiConstants.client,
                  idKey: 'clientId',
                  fields: detailFields,
                  showAvatar: true,
                ),
              ),
              MenuItem(
                icon: Icons.tune,
                label: '공장별 항목 관리',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FactoryMappingScreen(),
                  ),
                ),
              ),
              MenuItem(
                icon: Icons.attach_money,
                label: '단가 관리',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UnitPriceScreen(),
                  ),
                ),
              ),
              if (_canManageInvitations)
                MenuItem(
                  icon: Icons.group,
                  label: '초대 계정 관리',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InvitationManageScreen(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
            ),
          ),
        ],
      ),
    );
  }
}
