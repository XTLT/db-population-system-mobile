import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      if (person.huHao != null && person.huHao!.isNotEmpty) {
        try {
          familyMembers = await PersonApi.getFamilyMembers(person.huHao!);
        } catch (e) {
          
        }
      }
      
      setState(() {
        _person = person;
        _familyMembers = familyMembers;
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
            _buildInfoItem('电话', person.phone, copyable: true),
            _buildInfoItem('地址', person.address),
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
              _buildInfoItem('监护人电话', person.education?.guardianPhone ?? '', copyable: true),
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
  
  Widget _buildInfoItem(String label, String? value, {bool copyable = false}) {
    if (value == null || value.isEmpty) return const SizedBox();

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
          Expanded(
            child: copyable
                ? GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已复制: $value'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
        ],
      ),
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
              itemCount: _familyMembers.length + 1,
              itemBuilder: (context, index) {
                if (index == _familyMembers.length) {
                  
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
                
                final member = _familyMembers[index];
                
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
                      try {
                        await PersonApi.deletePerson(member.idCard!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已删除')),
                          );
                          _loadData();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
                          if (member.relation != null)
                            Text('关系: ${member.relation}'),
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('已删除')),
                                      );
                                      _loadData();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
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
