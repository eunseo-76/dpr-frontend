import 'package:dpr_frontend/core/models/field_config.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/widgets/confirm_dialog.dart';
import 'package:dpr_frontend/core/widgets/name_avatar.dart';
import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/widgets/form_dialog.dart';
import 'package:dpr_frontend/core/widgets/shake_field.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

class MasterDataManageScreen extends StatefulWidget {
  final String title;
  final MasterDataService service;
  final List<FieldConfig> fields;
  final bool showAvatar;
  final void Function(BuildContext, MasterDataEntity?, VoidCallback)? dialogBuilder;

  const MasterDataManageScreen({
    super.key,
    required this.title,
    required this.service,
    required this.fields,
    this.showAvatar = false,
    this.dialogBuilder,
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
    final confirmed = await showConfirmDialog(
      context,
      title: "'${item.name}' 삭제",
      content: '삭제된 항목은 되살릴 수 없습니다.\n기존 데이터(생산실적 등)는 유지됩니다.',
      confirmLabel: '삭제',
      isDestructive: true,
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
    if (widget.dialogBuilder != null) {
      widget.dialogBuilder!(context, item, _loadItems);
      return;
    }
    final isEdit = item != null;

    final controllers = widget.fields.map((field) {
      final controller = TextEditingController();
      if (isEdit) {
        final value = item.data[field.key];
        if (value != null) controller.text = value.toString();
      }
      return controller;
    }).toList();

    final initialValues = controllers.map((c) => c.text).toList();

    final shakeKeys = List.generate(
      widget.fields.length,
      (_) => GlobalKey<ShakeFieldState>(),
    );

    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          bool hasChanges() {
            for (var i = 0; i < controllers.length; i++) {
              if (controllers[i].text.trim() != initialValues[i]) return true;
            }
            return false;
          }

          void listen() => setDialogState(() {});

          for (final c in controllers) {
            c.removeListener(listen);
            c.addListener(listen);
          }

          return FormDialog(
            title: isEdit ? '수정' : '추가',
            subtitle: '* 는 필수 항목입니다',
            hasChanges: hasChanges(),
            isLoading: isSaving,
            onSave: () async {
              bool hasError = false;
              for (var i = 0; i < widget.fields.length; i++) {
                final text = controllers[i].text.trim();
                final field = widget.fields[i];
                if (field.required && text.isEmpty) {
                  shakeKeys[i].currentState?.showError('필수 항목입니다');
                  hasError = true;
                } else if (field.maxLength != null && text.length > field.maxLength!) {
                  shakeKeys[i].currentState?.showError('${field.maxLength}글자 이하로 입력하세요');
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.fields.length, (i) {
                final field = widget.fields[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ShakeField(
                    key: shakeKeys[i],
                    controller: controllers[i],
                    maxLength: field.maxLength,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: field.required ? '${field.label} *' : field.label,
                      labelStyle: TextStyle(color: Colors.grey[500]),
                      floatingLabelStyle: const TextStyle(color: Colors.black87),
                      helperText: field.maxLength != null ? '${field.maxLength}글자 이하로 입력하세요' : null,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
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
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: widget.showAvatar ? NameAvatar(name: item.name, size: 36, fontSize: 14) : null,
              title: Text(item.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.grey[400], size: 20),
                    onPressed: () => _showFormDialog(item: item),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showFormDialog(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.add, size: 20, color: Colors.grey[700]),
              ),
            ),
          ),
        ],
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
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}