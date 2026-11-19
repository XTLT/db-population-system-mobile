import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/person.dart';
import '../../api/person_api.dart';
import 'person_edit_page.dart';
import '../photo/photo_manage_page.dart';

class PersonDetailPage extends StatefulWidget {
  final String idCard;
  
  const PersonDetailPage({super.key, required this.idCard});

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Person? _person;
  List<Person> _familyMembers = [];
  /// 成员原始字段（身份证 -> 原始 Map），用于展示 subsidy_amount / student_mark
  Map<String, Map<String, dynamic>> _familyRaw = {};
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _subsidies;
  String? _subsidiesError;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  Future<void> _loadData() async {
    debugPrint('========== 加载人员详情 ==========');
    debugPrint('身份证: ${widget.idCard}');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      
      final person = await PersonApi.getPersonDetail(widget.idCard);
      
      
      List<Person> familyMembers = [];
      Map<String, Map<String, dynamic>> familyRaw = {};
      if (person.huHao != null && person.huHao!.isNotEmpty) {
        try {
          final rawList = await PersonApi.getFamilyMembersRaw(person.huHao!);
          familyMembers = rawList
              .map((json) => Person.fromJson(json))
              .toList();
          for (final json in rawList) {
            final key = (json['id_card'] ?? '').toString();
            if (key.isNotEmpty) familyRaw[key] = json;
          }
        } catch (e) {
          // 家庭成员加载失败不阻塞详情页主体，只影响"家庭成员"页签
          debugPrint('加载家庭成员失败: $e');
        }
      }

      // 补贴发放记录：失败不影响详情页主体，只在"补贴发放"页签内提示
      Map<String, dynamic>? subsidies;
      String? subsidiesError;
      if (person.idCard != null && person.idCard!.isNotEmpty) {
        try {
          subsidies = await PersonApi.getPersonSubsidies(person.idCard!);
        } catch (e) {
          subsidiesError = e.toString();
        }
      }
      
      setState(() {
        _person = person;
        _familyMembers = familyMembers;
        _familyRaw = familyRaw;
        _subsidies = subsidies;
        _subsidiesError = subsidiesError;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_person?.displayName ?? '人员详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: '照片管理',
            onPressed: _person == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoManagePage(
                          idCard: widget.idCard,
                          personName: _person!.displayName,
                        ),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _person == null
                ? null
                : () async {
                    debugPrint('点击编辑按钮');
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PersonEditPage(person: _person),
                      ),
                    );
                    
                    debugPrint('编辑页面返回结果: $result');
                    
                    if (result == true) {
                      debugPrint('开始重新加载数据');
                      
                      _loadData();
                    } else {
                      debugPrint('返回值不是 true，不刷新');
                    }
                  },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '基本信息'),
            Tab(text: '家庭成员'),
            Tab(text: '补贴发放'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('加载失败: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBasicInfo(),
                    _buildFamilyMembers(),
                    _buildSubsidies(),
                  ],
                ),
    );
  }
  
  Widget _buildBasicInfo() {
    if (_person == null) {
      return const Center(child: Text('无数据'));
    }
    
    final person = _person!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      person.name?.substring(0, 1) ?? '?',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            if (person.name != null && person.name!.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: person.name!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('已复制姓名: ${person.name}'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          child: Text(
                            person.displayName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (person.age != null && person.age!.isNotEmpty)
                              Chip(
                                label: Text(person.displayAge),
                                backgroundColor: Colors.blue.shade100,
                              ),
                            if (person.isDeceased) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: const Text('已死亡'),
                                backgroundColor: Colors.red.shade100,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          
          _buildInfoSection('身份信息', [
            _buildInfoItem('身份证号', person.idCard, copyable: true),
            _buildInfoItem('户号', person.huHao),
            _buildInfoItem('与户主关系', person.relation),
          ]),

          _buildInfoSection('联系信息', [
            _buildInfoItem('电话', person.phone, copyable: true, dialable: true),
            _buildInfoItem('地址', person.address),
            if (person.groupName != null && person.groupName!.isNotEmpty)
              _buildInfoItem('小组', person.groupName),
          ]),

          _buildInfoSection('社会保障', [
            _buildInfoItem('脱贫户或监测户', person.poorType),
            _buildInfoItem('残疾', person.disability),
            if (person.disability == '是') ...[
              _buildInfoItem('残疾类型', person.disabilityType),
              _buildInfoItem('残疾等级', person.disLevel),
            ],
            _buildInfoItem('低保', person.dibao),
            _buildInfoItem('是否计生家庭', person.jisheng),
            _buildInfoItem('是否特困供养', person.tekun),
            if (person.tekun == '是') ...[
              _buildInfoItem('供养类型', person.tekunType),
            ],
          ]),

          _buildInfoSection('社保卡信息', [
            _buildInfoItem('社保卡号1', person.socialCard1, copyable: true),
            _buildInfoItem('社保卡号2', _socialCardWithSource(person.socialCard2, person.socialCard2Source), copyable: true),
            _buildInfoItem('社保卡号3', _socialCardWithSource(person.socialCard3, person.socialCard3Source), copyable: true),
          ]),

          
          if (person.education != null) ...[
            _buildInfoSection('就读信息', [
              _buildInfoItem('学校名称', person.education?.schoolName ?? ''),
              _buildInfoItem('年级', _gradeDisplay(person.education?.grade ?? '')),
              _buildInfoItem('班级', person.education?.className ?? ''),
              _buildInfoItem('监护人', person.education?.guardian ?? ''),
              _buildInfoItem('监护人电话', person.education?.guardianPhone ?? '', copyable: true, dialable: true),
              _buildInfoItem('是否留守儿童', person.education?.isLeftBehind ?? ''),
              _buildInfoItem('学生状态', person.education?.studentStatus ?? ''),
              _buildInfoItem('入学日期', person.education?.enrollmentDate ?? ''),
              _buildInfoItem('毕业时间', person.education?.graduationDate ?? ''),
            ]),
          ],

          _buildInfoSection('其他信息', [
            _buildInfoItem('土地面积', person.landArea),
            _buildInfoItem('地方公益林', person.localWelfareForestArea),
            _buildInfoItem('国家公益林', person.nationalWelfareForestArea),
            _buildInfoItem('非国有天然商品林', person.commercialForestArea),
            _buildInfoItem('林地总面积', _calculateForestTotal(person)),
            _buildInfoItem('备注', person.remark),
          ]),
        ],
      ),
    );
  }
  
  String? _calculateForestTotal(Person person) {
    final local = double.tryParse(person.localWelfareForestArea ?? '') ?? 0;
    final national = double.tryParse(person.nationalWelfareForestArea ?? '') ?? 0;
    final commercial = double.tryParse(person.commercialForestArea ?? '') ?? 0;
    final total = local + national + commercial;
    if (total == 0) return null;
    return total.toStringAsFixed(2);
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    final nonNullChildren = children.where((w) => w != const SizedBox()).toList();
    
    if (nonNullChildren.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: nonNullChildren,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  /// 一键拨号：优先呼出拨号盘，失败时复制号码并提示
  Future<void> _dialPhone(String phone) async {
    final number = phone.replaceAll(RegExp(r'\s'), '');
    final uri = Uri(scheme: 'tel', path: number);
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && mounted) {
      await Clipboard.setData(ClipboardData(text: number));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('设备无法拨号，已复制号码: $number'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildInfoItem(
    String label,
    String? value, {
    bool copyable = false,
    bool dialable = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox();

    final valueText = Text(value, style: const TextStyle(fontSize: 14));

    Widget valueWidget;
    if (dialable) {
      valueWidget = InkWell(
        onTap: () => _dialPhone(value),
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已复制: $value'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Row(
          children: [
            Flexible(child: valueText),
            const SizedBox(width: 6),
            Icon(Icons.phone_in_talk, size: 16, color: Colors.blue.shade600),
          ],
        ),
      );
    } else if (copyable) {
      valueWidget = GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已复制: $value'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: valueText,
      );
    } else {
      valueWidget = valueText;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
  
  /// "补贴发放"页签：展示服务端按人聚合的 6 类补贴记录
  Widget _buildSubsidies() {
    if (_subsidiesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('补贴记录加载失败：$_subsidiesError',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final data = _subsidies;
    final List<Map<String, dynamic>> byModule =
        ((data?['by_module'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    final List<Map<String, dynamic>> records =
        ((data?['records'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    final int totalCount = (data?['total_count'] as num?)?.toInt() ?? 0;
    final bool truncated = data?['truncated'] == true;

    if (totalCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('该人员暂无补贴发放记录',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Text('低保 / 高龄 / 地力 / 残疾护理 / 养老 / 特困 六类均无数据',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final children = <Widget>[];

    // 六类汇总卡
    children.add(Wrap(
      spacing: 8,
      runSpacing: 8,
      children: byModule.map((m) {
        final count = (m['count'] as num?)?.toInt() ?? 0;
        final amt = (m['total_amount'] ?? '').toString();
        return Container(
          width: 106,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: count > 0 ? Colors.blue.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((m['label'] ?? '').toString(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('$count 笔',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              if (amt.isNotEmpty)
                Text('¥$amt',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
            ],
          ),
        );
      }).toList(),
    ));

    children.add(const SizedBox(height: 12));
    children.add(Text(
      truncated ? '发放明细（共 $totalCount 笔，仅显示最近 300 条）' : '发放明细（共 $totalCount 笔）',
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
    ));
    children.add(const SizedBox(height: 8));

    for (final r in records) {
      children.add(_buildSubsidyRecordTile(r));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: children,
    );
  }

  /// 单条补贴发放记录：模块标签 + 期数 + 金额 + 支付状态（失败标红）
  Widget _buildSubsidyRecordTile(Map<String, dynamic> r) {
    final status = (r['payment_status'] ?? '').toString();
    final failReason = (r['fail_reason'] ?? '').toString();
    final amount = (r['amount'] ?? '').toString();
    final period = (r['period'] ?? '').toString();
    final label = (r['label'] ?? '').toString();

    final bool failed = failReason.isNotEmpty || status.contains('失败');
    final bool paid = !failed &&
        (status.contains('成功') ||
            status.contains('已支付') ||
            status.contains('已发') ||
            status.contains('已上账'));
    final Color statusColor =
        failed ? Colors.red : (paid ? Colors.green : Colors.grey.shade600);

    final subtitleParts = <String>[];
    if (status.isNotEmpty) subtitleParts.add(failed ? '未发放（$status）' : '状态: $status');
    if (failReason.isNotEmpty) subtitleParts.add('原因: $failReason');

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade800)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(period.isEmpty ? '（无期数）' : period,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitleParts.isNotEmpty)
                    Text(subtitleParts.join('  '),
                        style: TextStyle(fontSize: 12, color: statusColor)),
                ],
              ),
            ),
            Text(amount.isEmpty ? '' : '¥$amount',
                style: TextStyle(fontSize: 14, color: Colors.orange.shade800)),
          ],
        ),
      ),
    );
  }

  /// 户信息卡：户号 / 户主 / 总人数 / 在世人数 / 当年补贴合计
  Widget _buildHouseholdHeader() {
    final huHao = _person?.huHao ?? '';
    final total = _familyMembers.length;
    final alive = _familyMembers.where((m) => !m.isDeceased).length;

    String householderName = '';
    for (final m in _familyMembers) {
      final raw = _familyRaw[(m.idCard ?? '').toString()];
      final relation = ((raw?['relation'] ?? m.relation) ?? '').toString();
      if (relation.contains('户主')) {
        householderName = m.name ?? '';
        break;
      }
    }

    double subsidyTotal = 0;
    for (final raw in _familyRaw.values) {
      final s = (raw['subsidy_amount'] ?? '')
          .toString()
          .replaceAll(',', '')
          .trim();
      final d = double.tryParse(s);
      if (d != null) subsidyTotal += d;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_outlined, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                '户号 ${huHao.isEmpty ? "未知" : huHao}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildHouseholdStat(
                  '户主', householderName.isEmpty ? '未标注' : householderName),
              _buildHouseholdStat('总人数', '$total 人'),
              _buildHouseholdStat('在世', '$alive 人'),
              if (subsidyTotal > 0)
                _buildHouseholdStat(
                    '当年地力补贴', '¥${subsidyTotal.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdStat(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label：',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }

  /// 成员标签行：户主 / 死亡 / 迁出 / 低保 / 特困 / 残疾 / 计生 / 脱贫类型
  Widget _buildMemberTags(Person m) {
    final raw = _familyRaw[(m.idCard ?? '').toString()];
    final tags = <Widget>[];

    final relation = ((raw?['relation'] ?? m.relation) ?? '').toString();
    if (relation.contains('户主')) tags.add(_memberTag('户主', Colors.blue));
    if (m.isDeceased) {
      tags.add(_memberTag('已死亡', Colors.red));
    } else if ((m.isMigrated ?? '') == '是') {
      tags.add(_memberTag('已迁出', Colors.orange));
    }

    if ((m.dibao ?? '') == '是') tags.add(_memberTag('低保', Colors.green));
    if ((m.tekun ?? '') == '是') tags.add(_memberTag('特困', Colors.deepOrange));
    if ((m.disability ?? '') == '是') tags.add(_memberTag('残疾', Colors.cyan));
    if ((m.jisheng ?? '') == '是') tags.add(_memberTag('计生', Colors.teal));

    final poorType = (m.poorType ?? '').toString();
    if (poorType.isNotEmpty && poorType != '一般户') {
      tags.add(_memberTag(poorType, Colors.brown));
    }

    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 4, runSpacing: 4, children: tags),
    );
  }

  /// 成员当年补贴额 + 学生标记（服务端 /api/family 已带回，此前被模型丢弃）
  Widget _buildMemberSubsidyLine(Person m) {
    final raw = _familyRaw[(m.idCard ?? '').toString()];
    final subsidy = (raw?['subsidy_amount'] ?? '').toString().trim();
    final studentMark = (raw?['student_mark'] ?? '').toString().trim();
    if (subsidy.isEmpty && studentMark.isEmpty) return const SizedBox.shrink();

    final parts = <String>[
      if (subsidy.isNotEmpty) '当年地力补贴 ¥$subsidy',
      if (studentMark.isNotEmpty) studentMark,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        parts.join('  ·  '),
        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
      ),
    );
  }

  Widget _memberTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color.shade800)),
    );
  }

  Widget _buildFamilyMembers() {
    return Scaffold(
      body: _familyMembers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无家庭成员信息',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addFamilyMember,
                    icon: const Icon(Icons.add),
                    label: const Text('添加家庭成员'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _familyMembers.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildHouseholdHeader();
                }
                if (index == _familyMembers.length + 1) {
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _addFamilyMember,
                      icon: const Icon(Icons.add),
                      label: const Text('添加家庭成员'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  );
                }
                
                final member = _familyMembers[index - 1];
                
                return Dismissible(
                  key: Key(member.id ?? member.idCard ?? index.toString()),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('确认删除'),
                        content: Text('确定要删除 ${member.name} 吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    if (member.idCard != null) {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await PersonApi.deletePerson(member.idCard!);
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('已删除')),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('删除失败: $e')),
                          );
                        }
                      }
                    }
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(member.name?.substring(0, 1) ?? '?'),
                      ),
                      title: Text(member.displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('身份证: ${member.idCard ?? "未知"}'),
                          if (member.relation != null &&
                              member.relation!.isNotEmpty)
                            Text('关系: ${member.relation}'),
                          _buildMemberTags(member),
                          _buildMemberSubsidyLine(member),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (member.isDeceased)
                            Chip(
                              label: const Text('已死亡'),
                              backgroundColor: Colors.red.shade100,
                            ),
                          if (member.idCard != widget.idCard)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('确认删除'),
                                    content: Text('确定要删除 ${member.name} 吗？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('取消'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: const Text('删除'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && member.idCard != null) {
                                  try {
                                    await PersonApi.deletePerson(member.idCard!);
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('已删除')),
                                      );
                                      _loadData();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('删除失败: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                      onTap: () {
                        if (member.idCard != null && member.idCard != widget.idCard) {
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PersonDetailPage(idCard: member.idCard!),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
  
  void _addFamilyMember() {
    
    if (_person?.huHao == null || _person!.huHao!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法添加家庭成员：当前人员户号为空')),
      );
      return;
    }

    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonEditPage(
          initialHuHao: _person?.huHao,  
        ),
      ),
    ).then((result) {
      if (result == true) {
        
        _loadData();
      }
    });
  }
}


// 社保卡号2/3 仅由补贴导入自动回填，展示为 卡号+来源（如 6217********（低保202606））
String? _socialCardWithSource(String? card, String? source) {
  if (card == null || card.isEmpty || card == '无') return null;
  final s = (source != null && source.isNotEmpty) ? '（$source）' : '';
  return '$card$s';
}

String? _gradeDisplay(String? grade) {
  if (grade == null || grade.isEmpty) return null;
  const gradeMap = {
    'T1': '托班',
    'K1': '幼儿园小班', 'K2': '幼儿园中班', 'K3': '幼儿园大班',
    'G1': '小学1年级', 'G2': '小学2年级', 'G3': '小学3年级',
    'G4': '小学4年级', 'G5': '小学5年级', 'G6': '小学6年级',
    'G7': '初中1年级', 'G8': '初中2年级', 'G9': '初中3年级',
    'G10': '高中1年级', 'G11': '高中2年级', 'G12': '高中3年级',
    'V1': '职高1年级', 'V2': '职高2年级', 'V3': '职高3年级',
    'J1': '技校1年级', 'J2': '技校2年级', 'J3': '技校3年级',
    'C1': '中专1年级', 'C2': '中专2年级', 'C3': '中专3年级',
    'Z1': '专科1年级', 'Z2': '专科2年级', 'Z3': '专科3年级',
    'U1': '大学1年级', 'U2': '大学2年级', 'U3': '大学3年级',
    'U4': '大学4年级', 'U5': '大学5年级',
    'M1': '硕士1年级', 'M2': '硕士2年级', 'M3': '硕士3年级',
    'D1': '博士1年级', 'D2': '博士2年级', 'D3': '博士3年级', 'D4': '博士4年级',
    'GRADUATED': '已毕业',
    '1': '小学1年级', '2': '小学2年级', '3': '小学3年级',
    '4': '小学4年级', '5': '小学5年级', '6': '小学6年级',
    '7': '初中1年级', '8': '初中2年级', '9': '初中3年级',
    '10': '高中1年级', '11': '高中2年级', '12': '高中3年级',
  };
  return gradeMap[grade] ?? grade;
}
