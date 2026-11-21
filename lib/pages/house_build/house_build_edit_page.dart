import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/house_build_api.dart';

/// 宅基地建房申请录入/编辑：申请表 + 审批表两个页签，保存后可导出 Excel/PDF。
class HouseBuildEditPage extends StatefulWidget {
  final String? appId;

  const HouseBuildEditPage({super.key, this.appId});

  @override
  State<HouseBuildEditPage> createState() => _HouseBuildEditPageState();
}

class _HouseBuildEditPageState extends State<HouseBuildEditPage> {
  final Map<String, dynamic> _data = {};
  final List<Map<String, dynamic>> _members = [];
  final Map<String, Map<String, dynamic>> _approvals = {};
  final _idCardController = TextEditingController();

  int _version = 0;
  bool _loading = false;
  bool _saving = false;
  String _appNo = '';
  String _historyNote = '';
  String _appId = '';

  static const _statusOptions = [
    ['draft', '草稿'],
    ['submitted', '已提交'],
    ['approved', '已审批'],
  ];
  static const _disposalOptions = [
    ['', '未选择'],
    ['1', '1.保留'],
    ['2', '2.退给村集体'],
    ['3', '3.其他'],
  ];
  static const _buildTypeOptions = [
    ['', '未选择'],
    ['1', '1.原址翻建'],
    ['2', '2.改扩建'],
    ['3', '3.异址新建'],
  ];
  static const _landTypeOptions = [
    ['', '未选择'],
    ['1', '1.建设用地'],
    ['2', '2.未利用地'],
    ['3', '3.农用地'],
  ];
  static const _yesNoOptions = [
    ['', '未选择'],
    ['1', '1.是'],
    ['2', '2.否'],
  ];
  static const _mirrorSourceKeys = [
    'foundation_area', 'build_type', 'land_type',
    'house_floor_area', 'floors', 'building_height',
  ];
  static const _approvalGroups = [
    ['natural', '乡镇自然资源机构意见'],
    ['housing', '乡镇住房建设机构意见'],
    ['agriculture', '乡镇农业农村机构审查意见'],
    ['other', '其他机构部门审批意见'],
    ['government', '乡镇政府、街道办事处审批意见'],
  ];

  @override
  void initState() {
    super.initState();
    _appId = widget.appId ?? '';
    for (final group in _approvalGroups) {
      _approvals[group[0]] = {'opinion': '', 'leader': '', 'date': ''};
    }
    if (_appId.isNotEmpty) {
      _loadDetail();
    } else {
      _data['status'] = 'draft';
    }
  }

  @override
  void dispose() {
    _idCardController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    try {
      final detail = await HouseBuildApi.get(_appId);
      setState(() {
        _data
          ..clear()
          ..addAll(detail);
        _appNo = (detail['app_no'] ?? '').toString();
        _idCardController.text = (detail['owner_id_card'] ?? '').toString();
        _members
          ..clear()
          ..addAll(((detail['members'] ?? []) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map)));
        final approvals = (detail['approvals'] ?? {}) as Map<String, dynamic>;
        for (final group in _approvalGroups) {
          final item = (approvals[group[0]] ?? {}) as Map<String, dynamic>;
          _approvals[group[0]] = {
            'opinion': (item['opinion'] ?? '').toString(),
            'leader': (item['leader'] ?? '').toString(),
            'date': (item['date'] ?? '').toString(),
          };
        }
        _historyNote = (detail['hu_hao'] ?? '').toString().isEmpty
            ? ''
            : '户号 ${detail['hu_hao']}（一户可多次申请，历史记录会保留）';
        _version++;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _prefill() async {
    final idCard = _idCardController.text.trim().toUpperCase();
    if (idCard.isEmpty) {
      _toast('请先输入申请人身份证号');
      return;
    }
    try {
      final result = await HouseBuildApi.prefill(idCard);
      if (result['found'] != true) {
        _toast((result['message'] ?? '人口库中没有该身份证号').toString());
        return;
      }
      setState(() {
        for (final key in [
          'owner_name',
          'owner_gender',
          'owner_age',
          'owner_phone',
          'owner_id_card',
          'owner_hukou',
          'hu_hao',
          'group_name',
        ]) {
          _data[key] = result[key] ?? '';
        }
        _members
          ..clear()
          ..addAll(((result['members'] ?? []) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map)));
        final history = (result['history'] ?? []) as List<dynamic>;
        if (history.isNotEmpty) {
          final parts = history
              .take(3)
              .map((e) {
                final m = e as Map<String, dynamic>;
                return '${m['app_no']}（${(m['created_at'] ?? '').toString().split(' ').first}，${m['apply_land_area']} ㎡）';
              })
              .join('；');
          _historyNote = '该户已有 ${history.length} 条申请：$parts';
        } else {
          _historyNote = '户号 ${_data['hu_hao']}（一户可多次申请，历史记录会保留）';
        }
        _version++;
      });
      _toast('已带出 ${_data['owner_name']} 及户内成员 ${_members.length} 人');
    } catch (e) {
      _toast('$e');
    }
  }

  Map<String, dynamic> _payload() {
    final members = <Map<String, dynamic>>[];
    for (int i = 0; i < _members.length; i++) {
      final m = _members[i];
      final name = (m['name'] ?? '').toString().trim();
      final idCard = (m['id_card'] ?? '').toString().trim();
      if (name.isEmpty && idCard.isEmpty) continue;
      members.add({
        'seq': '${members.length + 1}',
        'name': name,
        'age': (m['age'] ?? '').toString().trim(),
        'relation': (m['relation'] ?? '').toString().trim(),
        'id_card': idCard,
        'hukou': (m['hukou'] ?? '').toString().trim(),
      });
    }
    final payload = <String, dynamic>{};
    // 审批表与申请表重复的项统一取申请表，避免录两次
    _data['approval_foundation_area'] = _data['foundation_area'];
    _data['approval_build_type'] = _data['build_type'];
    _data['approval_land_type'] = _data['land_type'];
    _data['approval_house_floor_area'] = _data['house_floor_area'];
    _data['approval_floors'] = _data['floors'];
    _data['approval_height'] = _data['building_height'];
    if ((_data['approval_address'] ?? '').toString().trim().isEmpty) {
      _data['approval_address'] = _data['owner_hukou'];
    }
    for (final key in _appFieldKeys) {
      payload[key] = (_data[key] ?? '').toString().trim();
    }
    payload['approvals'] = {
      for (final group in _approvalGroups) group[0]: _approvals[group[0]],
    };
    payload['members'] = members;
    payload['status'] = (_data['status'] ?? 'draft').toString();
    return payload;
  }

  Future<void> _save() async {
    final ownerName = (_data['owner_name'] ?? '').toString().trim();
    final idCard = _idCardController.text.trim();
    final area = (_data['apply_land_area'] ?? '').toString().trim();
    if (ownerName.isEmpty) {
      _toast('申请人姓名不能为空');
      return;
    }
    if (idCard.isEmpty) {
      _toast('申请人身份证号不能为空');
      return;
    }
    if (area.isEmpty) {
      _toast('申请宅基地面积不能为空（会写入面积统计字段）');
      return;
    }
    _data['owner_id_card'] = idCard.toUpperCase();
    setState(() => _saving = true);
    try {
      final payload = _payload();
      final result = _appId.isEmpty
          ? await HouseBuildApi.create(payload)
          : await HouseBuildApi.update(_appId, payload);
      final saved = (result['data'] ?? result) as Map<String, dynamic>;
      _appId = (saved['id'] ?? _appId).toString();
      _appNo = (saved['app_no'] ?? _appNo).toString();
      if (!mounted) return;
      _toast('已保存：$_appNo');
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _export(String fmt) async {
    if (_appId.isEmpty) {
      _toast('请先保存，再导出打印文件');
      return;
    }
    try {
      final path = await HouseBuildApi.download(_appId, fmt);
      await Share.shareXFiles([XFile(path)], text: '宅基地建房申请 $_appNo');
    } catch (e) {
      _toast('$e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static const _appFieldKeys = [
    'owner_name', 'owner_gender', 'owner_age', 'owner_phone', 'owner_id_card',
    'owner_hukou', 'hu_hao', 'group_name',
    'apply_land_area', 'building_area', 'cert_no', 'current_disposal',
    'current_disposal_other', 'current_land_area', 'foundation_area',
    'east_to', 'south_to', 'west_to', 'north_to', 'build_type', 'land_type',
    'house_floor_area', 'floors', 'building_height', 'neighbor_opinion',
    'design_plan', 'apply_reason', 'village_opinion', 'village_leader',
    'village_date', 'approval_land_area', 'approval_foundation_area',
    'approval_address', 'approval_build_type', 'approval_land_type',
    'approval_house_floor_area', 'approval_floors', 'approval_height',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appId.isEmpty
              ? '新建建房申请'
              : '建房申请 ${_appNo.isEmpty ? '' : _appNo}'),
          bottom: const TabBar(
            tabs: [Tab(text: '申请表'), Tab(text: '审批表')],
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
            PopupMenuButton<String>(
              onSelected: _export,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'xlsx', child: Text('导出 Excel')),
                PopupMenuItem(value: 'pdf', child: Text('导出 PDF')),
              ],
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildApplyTab(),
                  _buildApprovalTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildApplyTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _card('从人口库带出', [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _idCardController,
                  decoration: const InputDecoration(
                    labelText: '申请人身份证号',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _prefill,
                child: const Text('带出'),
              ),
            ],
          ),
          if (_historyNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_historyNote,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ]),
        _card('申请人信息', [
          _field('owner_name', '姓名'),
          _dropdown('owner_gender', '性别', const [
            ['', '未填'],
            ['男', '男'],
            ['女', '女'],
          ]),
          _field('owner_age', '年龄', keyboard: TextInputType.number),
          _field('owner_phone', '联系电话', keyboard: TextInputType.phone),
          _field('owner_hukou', '户口所在地'),
          _field('hu_hao', '户号'),
          _field('group_name', '小组'),
          _dropdown('status', '状态', _statusOptions),
        ]),
        _card('家庭成员（最多打印 5 人）', [
          for (int i = 0; i < _members.length; i++) _memberRow(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _members.add({
                    'seq': '${_members.length + 1}',
                    'name': '',
                    'age': '',
                    'relation': '',
                    'id_card': '',
                    'hukou': '',
                  });
                  _version++;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('添加成员'),
            ),
          ),
        ]),
        _card('拟申请建房情况（面积单位：m²）', [
          _field('apply_land_area', '申请宅基地面积', keyboard: TextInputType.number, suffix: 'm²'),
          _field('building_area', '建筑面积', keyboard: TextInputType.number, suffix: 'm²'),
          _field('cert_no', '权属证书号'),
          _dropdown('current_disposal', '现宅基地处置', _disposalOptions),
          _field('current_disposal_other', '处置其他说明'),
          _field('current_land_area', '原宅基地面积', keyboard: TextInputType.number, suffix: 'm²'),
          _field('foundation_area', '房基占地面积', keyboard: TextInputType.number, suffix: 'm²'),
          _field('east_to', '东至'),
          _field('south_to', '南至'),
          _field('west_to', '西至'),
          _field('north_to', '北至'),
          _dropdown('build_type', '建房类型', _buildTypeOptions),
          _dropdown('land_type', '地类', _landTypeOptions),
          _field('house_floor_area', '住房建筑面积', keyboard: TextInputType.number, suffix: 'm²'),
          _field('floors', '建筑层数', keyboard: TextInputType.number),
          _field('building_height', '建筑高度', keyboard: TextInputType.number),
          _dropdown('neighbor_opinion', '征求相邻权利人意见', _yesNoOptions),
          _dropdown('design_plan', '是否有设计方案/通用图集', _yesNoOptions),
        ]),
        _card('申请理由', [
          _field('apply_reason', '申请理由', lines: 3),
        ]),
        _card('村（组）意见', [
          _field('village_opinion', '意见', lines: 3),
          _field('village_leader', '负责人（仅存档，打印留空）'),
          _field('village_date', '日期（仅存档，打印留空）', hint: '如 2025年11月20日'),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildApprovalTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _card('拟批准情况（灰色项沿用申请表，不用重复填；面积单位：m²）', [
          _field('approval_land_area', '批准宅基地面积', keyboard: TextInputType.number, suffix: 'm²'),
          _mirror('房基占地面积', 'foundation_area', suffix: ' m²'),
          _field('approval_address', '建房地址', hint: '不填默认用户口所在地'),
          _mirror('建房类型', 'build_type', options: _buildTypeOptions),
          _mirror('地类', 'land_type', options: _landTypeOptions),
          _mirror('住房建筑面积', 'house_floor_area', suffix: ' m²'),
          _mirror('建筑层数', 'floors'),
          _mirror('建筑高度', 'building_height'),
        ]),
        _card('提示', [
          const Text(
            '审批表打印时五个机构意见格按空表原文（示例意见 +（盖章）+ 空白负责人/年月日），'
            '下面填写的意见与负责人仅存档、不打印。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ]),
        for (final group in _approvalGroups)
          _card(group[1], [
            _approvalField(group[0], 'opinion', '审批意见', lines: 3),
            _approvalField(group[0], 'leader', '负责人'),
            _approvalField(group[0], 'date', '日期', hint: '如 2026年11月20日'),
          ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(String key, String label,
      {TextInputType? keyboard, int lines = 1, String? hint, String? suffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: ValueKey('$key-$_version'),
        initialValue: (_data[key] ?? '').toString(),
        keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
        maxLines: lines > 1 ? lines : 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          _data[key] = value;
          if (_mirrorSourceKeys.contains(key)) setState(() {});
        },
      ),
    );
  }

  Widget _mirror(String label, String sourceKey, {List<List<String>>? options, String suffix = ''}) {
    var text = (_data[sourceKey] ?? '').toString().trim();
    if (options != null) {
      for (final option in options) {
        if (option[0] == text) {
          text = option[1];
          break;
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        child: Text(
          text.isEmpty ? '沿用申请表' : '$text$suffix',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget _dropdown(String key, String label, List<List<String>> options) {
    final value = (_data[key] ?? '').toString();
    final exists = options.any((e) => e[0] == value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$key-$_version'),
        initialValue: exists ? value : options.first[0],
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: options
            .map((e) => DropdownMenuItem<String>(value: e[0], child: Text(e[1])))
            .toList(),
        onChanged: (v) {
          _data[key] = v ?? '';
          if (_mirrorSourceKeys.contains(key)) setState(() {});
        },
      ),
    );
  }

  Widget _approvalField(String key, String field, String label,
      {int lines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        key: ValueKey('ap-$key-$field-$_version'),
        initialValue: (_approvals[key]?[field] ?? '').toString(),
        maxLines: lines > 1 ? lines : 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => _approvals[key]?[field] = value,
      ),
    );
  }

  Widget _memberRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('成员 ${index + 1}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () {
                  setState(() {
                    _members.removeAt(index);
                    _version++;
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _memberField(index, 'name', '姓名'),
              ),
              const SizedBox(width: 6),
              SizedBox(width: 70, child: _memberField(index, 'age', '年龄')),
              const SizedBox(width: 6),
              SizedBox(width: 90, child: _memberField(index, 'relation', '关系')),
            ],
          ),
          const SizedBox(height: 6),
          _memberField(index, 'id_card', '身份证号'),
          const SizedBox(height: 6),
          _memberField(index, 'hukou', '户口所在地'),
        ],
      ),
    );
  }

  Widget _memberField(int index, String field, String label) {
    return TextFormField(
      key: ValueKey('member-$index-$field-$_version'),
      initialValue: (_members[index][field] ?? '').toString(),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => _members[index][field] = value,
    );
  }
}
