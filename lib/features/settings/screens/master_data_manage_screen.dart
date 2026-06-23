import 'package:dpr_frontend/core/models/field_config.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/widgets/shake_field.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

class MasterDataManageScreen extends StatefulWidget {
  final String title;
  final MasterDataService service;
  final List<FieldConfig> fields;

  const MasterDataManageScreen({
    super.key,
    required this.title,
    required this.service,
    required this.fields,
  });

  @override
  State<MasterDataManageScreen> createState() => _MasterDataManageScreenState();
}

class _MasterDataManageScreenState extends State<MasterDataManageScreen> {
  List<MasterDataEntity> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await widget.service.getAll();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(MasterDataEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("'${item.name}'을(를) 삭제하시겠습니까?"),
            const SizedBox(height: 12),
            Text(
              '삭제된 항목은 되살릴 수 없습니다.\n기존 데이터(생산실적 등)는 유지됩니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await widget.service.delete(item.id);
      _loadItems();
    } catch (e) {
      if (mounted) showToast(context, '삭제 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showFormDialog({MasterDataEntity? item}) {
    final isEdit = item != null;

    // 1. 각 필드마다 TextEditingController 생성
    // widget.fields = [FieldConfig(key:'name', label:'이름'), FieldConfig(key:'nickname', label:'별칭')]
    // .map()으로 순회하면서 각각에 대응하는 controller를 만든다
    // 결과: controllers = [TextEditingController(), TextEditingController()]
    final controllers = widget.fields.map((field) {
      final controller = TextEditingController();
      // 수정 모드이고 key가 'name'이면 기존 이름을 채워넣기
      if (isEdit && field.key == 'name') {
        controller.text = item.name;
      }
      return controller;
    }).toList();

    final shakeKeys = List.generate(
      widget.fields.length,
      (_) => GlobalKey<ShakeFieldState>(),
    );

    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? '수정' : '추가'),
              Text(
                '* 는 필수 항목입니다',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.fields.length, (i) {
              final field = widget.fields[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ShakeField(
                  key: shakeKeys[i],
                  controller: controllers[i],
                  decoration: InputDecoration(
                    labelText: field.required
                        ? '${field.label} *'
                        : field.label,
                  ),
                ),
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: isSaving ? null : () async {
                bool hasError = false;
                for (var i = 0; i < widget.fields.length; i++) {
                  if (widget.fields[i].required &&
                      controllers[i].text.trim().isEmpty) {
                    shakeKeys[i].currentState?.showError('필수 항목입니다');
                    hasError = true;
                  } else {
                    shakeKeys[i].currentState?.clearError();
                  }
                }
                if (hasError) return;

                final body = <String, dynamic>{};
                for (var i = 0; i < widget.fields.length; i++) {
                  body[widget.fields[i].key] = controllers[i].text;
                }

                setDialogState(() => isSaving = true);
                try {
                  if (isEdit) {
                    await widget.service.update(item.id, body);
                  } else {
                    await widget.service.create(body);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _loadItems();
                } catch (e) {
                  if (dialogContext.mounted) {
                    setDialogState(() => isSaving = false);
                    showToast(dialogContext, '저장 실패: $e');
                  }
                }
              },
              child: isSaving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const LoadingIndicator();
    } else if (_error != null) {
      body = Center(child: Text('오류: $_error'));
    } else if (_items.isEmpty) {
      body = const Center(child: Text('등록된 항목이 없습니다'));
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _showFormDialog(item: item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => _deleteItem(item),
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFormDialog(),
          ),
        ],
      ),
      body: body,
    );
  }
}