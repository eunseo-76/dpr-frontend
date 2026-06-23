import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/models/field_config.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/widgets/menu_card.dart';
import 'package:dpr_frontend/features/settings/screens/factory_mapping_screen.dart';
import 'package:dpr_frontend/features/settings/screens/master_data_manage_screen.dart';
import 'package:dpr_frontend/features/settings/screens/unit_price_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openManageScreen(
    BuildContext context, {
    required String title,
    required String endpoint,
    required String idKey,
    required List<FieldConfig> fields,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MasterDataManageScreen(
          title: title,
          service: MasterDataService(endpoint: endpoint, idKey: idKey),
          fields: fields,
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
            ],
          ),
        ],
      ),
    );
  }
}