import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/services/production_service.dart';
import 'package:flutter/material.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  late Future<List<Production>> _future; // 비동기 작업이라 나중에 초기화
  final _service = ProductionService();

  @override
  void initState() {
    super.initState();
    _future = _service.getProductionList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('생산실적')),
      body: FutureBuilder<List<Production>>(
        future: _future,
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }
          final list = snapshot.data!;
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('날짜: ${item.date}'),
                      Text('작성자: ${item.createdName}'),
                      Text('상태: ${item.status}'),
                      Text('주간: ${item.dayShift ?? '-'}'),
                      Text('야간: ${item.nightShift ?? '-'}'),
                      Text('실적: ${item.result ?? '-'}'),
                      Text('누적실적: ${item.cumulativeResult ?? '-'}'),
                      Text('공장ID: ${item.factoryId}'),
                      Text('공정ID: ${item.processId}'),
                      Text('고객ID: ${item.clientId}'),
                      Text('단위ID: ${item.unitId}'),
                      Text('수정일: ${item.updatedAt ?? '-'}'),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
