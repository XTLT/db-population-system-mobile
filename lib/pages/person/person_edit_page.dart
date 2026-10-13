import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/person.dart';
import '../../api/person_api.dart';
import '../../utils/validators.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_data_service.dart';
import '../../api/api_client.dart';

class PersonEditPage extends StatefulWidget {
  final Person? person; 
  final String? initialHuHao; 
  
  const PersonEditPage({super.key, this.person, this.initialHuHao});

  @override
  State<PersonEditPage> createState() => _PersonEditPageState();
}

class _PersonEditPageState extends State<PersonEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  
  late TextEditingController _idCardController;
  late TextEditingController _nameController;
  late TextEditingController _huHaoController;
  late TextEditingController _addressController;
  late TextEditingController _groupNameController;
  late TextEditingController _relationController;
  late TextEditingController _phoneController;
  late TextEditingController _remarkController;
  late TextEditingController _landAreaController;
  late TextEditingController _localWelfareForestAreaController;
  late TextEditingController _nationalWelfareForestAreaController;
  late TextEditingController _commercialForestAreaController;
  late TextEditingController _socialCard1Controller;
  late TextEditingController _socialCard2Controller;
  late TextEditingController _socialCard3Controller;
  
  late TextEditingController _schoolNameController;
  late TextEditingController _classNameController;
  late TextEditingController _guardianController;
  late TextEditingController _guardianPhoneController;
  late TextEditingController _enrollmentDateController;
  late TextEditingController _graduationDateController;
  
  
  String? _isDead;
  String? _poorType;
  String? _disability;
  String? _disabilityType;
  String? _disLevel;
  String? _dibao;
  String? _jisheng;
  String? _tekun;
  String? _tekunType;
  
  String? _grade;
  String? _isLeftBehind;
  String? _studentStatus;

  static const Map<String, String> _gradeOptions = {
    "T1": "托班",
    "K1": "幼儿园小班", "K2": "幼儿园中班", "K3": "幼儿园大班",
    "G1": "小学1年级", "G2": "小学2年级", "G3": "小学3年级",
    "G4": "小学4年级", "G5": "小学5年级", "G6": "小学6年级",
    "G7": "初中1年级", "G8": "初中2年级", "G9": "初中3年级",
    "G10": "高中1年级", "G11": "高中2年级", "G12": "高中3年级",
    "V1": "职高1年级", "V2": "职高2年级", "V3": "职高3年级",
    "J1": "技校1年级", "J2": "技校2年级", "J3": "技校3年级",
    "C1": "中专1年级", "C2": "中专2年级", "C3": "中专3年级",
    "Z1": "专科1年级", "Z2": "专科2年级", "Z3": "专科3年级",
    "U1": "大学1年级", "U2": "大学2年级", "U3": "大学3年级",
    "U4": "大学4年级", "U5": "大学5年级",
    "M1": "硕士1年级", "M2": "硕士2年级", "M3": "硕士3年级",
    "D1": "博士1年级", "D2": "博士2年级", "D3": "博士3年级", "D4": "博士4年级",
    "GRADUATED": "已毕业",
  };

  static final Map<String, String> _gradeDisplayToCode = {
    for (final e in _gradeOptions.entries) e.value: e.key
  };

  static const Map<String, String> _oldGradeToCode = {
    '一年级': 'G1', '二年级': 'G2', '三年级': 'G3',
    '四年级': 'G4', '五年级': 'G5', '六年级': 'G6',
    '七年级': 'G7', '八年级': 'G8', '九年级': 'G9',
    '高一': 'G10', '高二': 'G11', '高三': 'G12',
    '1': 'G1', '2': 'G2', '3': 'G3', '4': 'G4', '5': 'G5', '6': 'G6',
    '7': 'G7', '8': 'G8', '9': 'G9',
    '10': 'G10', '11': 'G11', '12': 'G12',
  };

  String? _normalizeGrade(String? grade) {
    if (grade == null || grade.isEmpty) return null;
    if (_gradeOptions.containsKey(grade)) return grade;
    if (_gradeDisplayToCode.containsKey(grade)) return _gradeDisplayToCode[grade];
    if (_oldGradeToCode.containsKey(grade)) return _oldGradeToCode[grade];
    return grade;
  }

  // 社保卡号2/3 仅由补贴导入自动回填，展示为 卡号+来源（如 6217********（低保202606））
  String _socialCardDisplay(String? card, String? source) {
    if (card == null || card.isEmpty || card == '无') return '';
    final s = (source != null && source.isNotEmpty) ? '（$source）' : '';
    return '$card$s';
  }
  
  bool _isLoading = false;
  bool _autoFillFromIdCard = false;
  String? _landAreaChangeReason;
  String? _localWelfareForestChangeReason;
  String? _nationalWelfareForestChangeReason;
  String? _commercialForestChangeReason;
  
  @override
  void initState() {
    super.initState();
    
    
    _idCardController = TextEditingController(text: widget.person?.idCard ?? '');
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _huHaoController = TextEditingController(
      text: widget.person?.huHao ?? widget.initialHuHao ?? ''
    );
    _addressController = TextEditingController(text: widget.person?.address ?? '');
    _groupNameController = TextEditingController(text: widget.person?.groupName ?? '');
    _relationController = TextEditingController(text: widget.person?.relation ?? '');
    _phoneController = TextEditingController(text: widget.person?.phone ?? '');
    _remarkController = TextEditingController(text: widget.person?.remark ?? '');
    _landAreaController = TextEditingController(text: widget.person?.landArea ?? '');
    _localWelfareForestAreaController = TextEditingController(text: widget.person?.localWelfareForestArea ?? '');
    _nationalWelfareForestAreaController = TextEditingController(text: widget.person?.nationalWelfareForestArea ?? '');
    _commercialForestAreaController = TextEditingController(text: widget.person?.commercialForestArea ?? '');
    _socialCard1Controller = TextEditingController(text: widget.person?.socialCard1 ?? '');
    _socialCard2Controller = TextEditingController(text: _socialCardDisplay(widget.person?.socialCard2, widget.person?.socialCard2Source));
    _socialCard3Controller = TextEditingController(text: _socialCardDisplay(widget.person?.socialCard3, widget.person?.socialCard3Source));

    
    _schoolNameController = TextEditingController(text: widget.person?.education?.schoolName ?? '');
    _classNameController = TextEditingController(text: widget.person?.education?.className ?? '');
    _guardianController = TextEditingController(text: widget.person?.education?.guardian ?? '');
    _guardianPhoneController = TextEditingController(text: widget.person?.education?.guardianPhone ?? '');
    _enrollmentDateController = TextEditingController(text: widget.person?.education?.enrollmentDate ?? '');
    _graduationDateController = TextEditingController(text: widget.person?.education?.graduationDate ?? '');

    
    _isDead = widget.person?.isDead;
    _poorType = widget.person?.poorType;
    _disability = widget.person?.disability;
    _disabilityType = widget.person?.disabilityType;
    _disLevel = widget.person?.disLevel;
    _dibao = widget.person?.dibao;
    _jisheng = widget.person?.jisheng;
    _tekun = widget.person?.tekun;
    _tekunType = widget.person?.tekunType;
    
    _grade = _normalizeGrade(widget.person?.education?.grade);
    _isLeftBehind = widget.person?.education?.isLeftBehind;
    _studentStatus = widget.person?.education?.studentStatus;
    
    
    _idCardController.addListener(_onIdCardChanged);
  }
  
  void _onIdCardChanged() {
    if (_autoFillFromIdCard) {
      final idCard = _idCardController.text;
      if (idCard.length == 15 || idCard.length == 18) {
        
        final error = Validators.validateIdCard(idCard);
        if (error == null) {
          
          setState(() {});
        }
      }
    }
  }
  
  @override
  void dispose() {
    _idCardController.dispose();
    _nameController.dispose();
    _huHaoController.dispose();
    _addressController.dispose();
    _groupNameController.dispose();
    _relationController.dispose();
    _phoneController.dispose();
    _remarkController.dispose();
    _landAreaController.dispose();
    _localWelfareForestAreaController.dispose();
    _nationalWelfareForestAreaController.dispose();
    _commercialForestAreaController.dispose();
    _socialCard1Controller.dispose();
    _socialCard2Controller.dispose();
    _socialCard3Controller.dispose();
    
    _schoolNameController.dispose();
    _classNameController.dispose();
    _guardianController.dispose();
    _guardianPhoneController.dispose();
    _enrollmentDateController.dispose();
    _graduationDateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  
  Map<String, String> _calculateEnrollmentAndGraduation() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    String? enrollmentDate = _enrollmentDateController.text.trim();
    String? graduationDate = _graduationDateController.text.trim();

    
    final gradeToYears = {
      'T1': 2,
      'K1': 3, 'K2': 2, 'K3': 1,
      'G1': 6, 'G2': 5, 'G3': 4, 'G4': 3, 'G5': 2, 'G6': 1,
      'G7': 3, 'G8': 2, 'G9': 1,
      'G10': 3, 'G11': 2, 'G12': 1,
      'V1': 3, 'V2': 2, 'V3': 1,
      'J1': 3, 'J2': 2, 'J3': 1,
      'C1': 3, 'C2': 2, 'C3': 1,
      'Z1': 3, 'Z2': 2, 'Z3': 1,
      'U1': 4, 'U2': 3, 'U3': 2, 'U4': 1, 'U5': 0,
      'M1': 3, 'M2': 2, 'M3': 1,
      'D1': 4, 'D2': 3, 'D3': 2, 'D4': 1,
    };

    final gradeToOffset = {
      'T1': 0,
      'K1': 0, 'K2': 1, 'K3': 2,
      'G1': 0, 'G2': 1, 'G3': 2, 'G4': 3, 'G5': 4, 'G6': 5,
      'G7': 0, 'G8': 1, 'G9': 2,
      'G10': 0, 'G11': 1, 'G12': 2,
      'V1': 0, 'V2': 1, 'V3': 2,
      'J1': 0, 'J2': 1, 'J3': 2,
      'C1': 0, 'C2': 1, 'C3': 2,
      'Z1': 0, 'Z2': 1, 'Z3': 2,
      'U1': 0, 'U2': 1, 'U3': 2, 'U4': 3, 'U5': 4,
      'M1': 0, 'M2': 1, 'M3': 2,
      'D1': 0, 'D2': 1, 'D3': 2, 'D4': 3,
    };

    if (_grade != null && _grade!.isNotEmpty) {
      final offset = gradeToOffset[_grade] ?? 0;

      
      
      
      int enrollmentYear;
      if (currentMonth >= 9) {
        enrollmentYear = currentYear - offset;
      } else {
        enrollmentYear = currentYear - offset - 1;
      }

      
      if (enrollmentDate.isEmpty) {
        enrollmentDate = '$enrollmentYear-09-01';
      }

      
      if (graduationDate.isEmpty) {
        final totalYears = gradeToYears[_grade] ?? 0;
        if (totalYears > 0) {
          
          
          final gradYear = enrollmentYear + totalYears;
          graduationDate = '$gradYear-06-30';
        }
      }
    }

    return {
      'enrollment_date': enrollmentDate,
      'graduation_date': graduationDate,
    };
  }

  Future<String?> _showLandAreaChangeDialog() async {
    final reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false, 
      builder: (context) => AlertDialog(
        title: const Text('土地面积变更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '土地面积已从 "${widget.person?.landArea ?? ''}" 亩修改为 "${_landAreaController.text.trim()}" 亩',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '请输入修改原因：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '例如：土地流转、测量修正等',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入修改原因')),
                );
                return;
              }
              Navigator.of(context).pop(reason);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    ).then((reason) {
      if (reason != null) {
        _landAreaChangeReason = reason;
      }
      return reason;
    });
  }

  Future<String?> _showLocalWelfareForestAreaChangeDialog() async {
    final reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('地方公益林变更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地方公益林已从 "${widget.person?.localWelfareForestArea ?? ''}" 亩修改为 "${_localWelfareForestAreaController.text.trim()}" 亩',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '请输入修改原因：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '例如：林地流转、测量修正等',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入修改原因')),
                );
                return;
              }
              Navigator.of(context).pop(reason);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    ).then((reason) {
      if (reason != null) {
        _localWelfareForestChangeReason = reason;
      }
      return reason;
    });
  }

  Future<String?> _showNationalWelfareForestAreaChangeDialog() async {
    final reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('国家公益林变更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '国家公益林已从 "${widget.person?.nationalWelfareForestArea ?? ''}" 亩修改为 "${_nationalWelfareForestAreaController.text.trim()}" 亩',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '请输入修改原因：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '例如：林地流转、测量修正等',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入修改原因')),
                );
                return;
              }
              Navigator.of(context).pop(reason);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    ).then((reason) {
      if (reason != null) {
        _nationalWelfareForestChangeReason = reason;
      }
      return reason;
    });
  }

  Future<String?> _showCommercialForestAreaChangeDialog() async {
    final reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('非国有天然商品林变更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '非国有天然商品林已从 "${widget.person?.commercialForestArea ?? ''}" 亩修改为 "${_commercialForestAreaController.text.trim()}" 亩',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '请输入修改原因：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '例如：林地流转、测量修正等',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入修改原因')),
                );
                return;
              }
              Navigator.of(context).pop(reason);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    ).then((reason) {
      if (reason != null) {
        _commercialForestChangeReason = reason;
      }
      return reason;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    
    final newLandArea = _landAreaController.text.trim();
    final oldLandArea = widget.person?.landArea ?? '';
    final newLocalWelfareForestArea = _localWelfareForestAreaController.text.trim();
    final oldLocalWelfareForestArea = widget.person?.localWelfareForestArea ?? '';
    final newNationalWelfareForestArea = _nationalWelfareForestAreaController.text.trim();
    final oldNationalWelfareForestArea = widget.person?.nationalWelfareForestArea ?? '';
    final newCommercialForestArea = _commercialForestAreaController.text.trim();
    final oldCommercialForestArea = widget.person?.commercialForestArea ?? '';
    
    
    if (widget.person != null && 
        newLandArea != oldLandArea && 
        oldLandArea.isNotEmpty) {
      final reason = await _showLandAreaChangeDialog();
      if (reason == null) {
        
        return;
      }
    }

    if (widget.person != null &&
        newLocalWelfareForestArea != oldLocalWelfareForestArea &&
        oldLocalWelfareForestArea.isNotEmpty) {
      final reason = await _showLocalWelfareForestAreaChangeDialog();
      if (reason == null) {
        return;
      }
    }

    if (widget.person != null &&
        newNationalWelfareForestArea != oldNationalWelfareForestArea &&
        oldNationalWelfareForestArea.isNotEmpty) {
      final reason = await _showNationalWelfareForestAreaChangeDialog();
      if (reason == null) {
        return;
      }
    }

    if (widget.person != null &&
        newCommercialForestArea != oldCommercialForestArea &&
        oldCommercialForestArea.isNotEmpty) {
      final reason = await _showCommercialForestAreaChangeDialog();
      if (reason == null) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'id_card': _idCardController.text.trim(),
        'name': _nameController.text.trim(),
        'hu_hao': _huHaoController.text.trim(),
        'address': _addressController.text.trim(),
        'group_name': _groupNameController.text.trim(),
        'relation': _relationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'is_dead': _isDead,
        'remark': _remarkController.text.trim(),
        'poor_type': _poorType,
        'disability': _disability,
        'disability_type': _disabilityType,
        'dis_level': _disLevel,
        'dibao': _dibao,
        'jisheng': _jisheng,
        'tekun': _tekun,
        'tekun_type': _tekunType,
        'social_card1': _socialCard1Controller.text.trim(),
        'land_area': newLandArea,
        'land_area_change_reason': _landAreaChangeReason ?? '',
        'local_welfare_forest_area': newLocalWelfareForestArea,
        'local_welfare_forest_change_reason': _localWelfareForestChangeReason ?? '',
        'national_welfare_forest_area': newNationalWelfareForestArea,
        'national_welfare_forest_change_reason': _nationalWelfareForestChangeReason ?? '',
        'commercial_forest_area': newCommercialForestArea,
        'commercial_forest_change_reason': _commercialForestChangeReason ?? '',
      };

      debugPrint('========== 保存数据 ==========');
      debugPrint('土地面积: $newLandArea');
      debugPrint('土地面积变更原因: $_landAreaChangeReason');
      debugPrint('地方公益林: $newLocalWelfareForestArea');
      debugPrint('地方公益林变更原因: $_localWelfareForestChangeReason');
      debugPrint('国家公益林: $newNationalWelfareForestArea');
      debugPrint('国家公益林变更原因: $_nationalWelfareForestChangeReason');
      debugPrint('非国有天然商品林: $newCommercialForestArea');
      debugPrint('非国有天然商品林变更原因: $_commercialForestChangeReason');
      debugPrint('完整数据: $data');
      debugPrint('============================');

      
      final isConnected = await ConnectivityService().isConnected();

      if (!isConnected) {
        
        await OfflineDataService().savePersonOffline(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已保存到离线队列，将在网络恢复后同步'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
        return;
      }

      
      bool success;
      String? personId;
      if (widget.person == null) {
        
        success = await PersonApi.addPerson(data);
      } else {
        
        final idCard = widget.person?.idCard ?? '';
        if (idCard.isEmpty) {
          throw Exception('人员身份证号为空，无法更新');
        }
        success = await PersonApi.updatePerson(
          idCard,
          data,
        );
        personId = widget.person?.id ?? idCard;
      }

      
      if (success && personId != null) {
        
        final hasEducation = _schoolNameController.text.trim().isNotEmpty ||
            _grade != null ||
            _classNameController.text.trim().isNotEmpty;

        if (hasEducation) {
          try {
            
            final dates = _calculateEnrollmentAndGraduation();

            await PersonApi.updateEducation(personId, {
              'school_name': _schoolNameController.text.trim(),
              'grade': _grade ?? '',
              'class_name': _classNameController.text.trim(),
              'guardian': _guardianController.text.trim(),
              'guardian_phone': _guardianPhoneController.text.trim(),
              'is_left_behind': _isLeftBehind ?? '否',
              'student_status': _studentStatus ?? '在读',
              'enrollment_date': dates['enrollment_date'] ?? _enrollmentDateController.text.trim(),
              'graduation_date': dates['graduation_date'] ?? _graduationDateController.text.trim(),
            });
          } catch (e) {
            
            debugPrint('保存就读信息失败: $e');
          }
        }
      }

      if (success && mounted) {
        debugPrint('========== 保存成功，返回 true ==========');
        // 清除统计缓存，确保统计数据及时更新
        ApiClient().invalidatePath('GET', '/api/statistics');
        ApiClient().invalidatePath('GET', '/api/students/statistics');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.person == null ? '添加成功' : '保存成功')),
        );
        Navigator.of(context).pop(true); 
      } else {
        debugPrint('========== 保存失败 ==========');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.person == null ? '新增人员' : '编辑人员'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  
                  _buildSection('基本信息', [
                    _buildTextField(
                      controller: _idCardController,
                      label: '身份证号 *',
                      validator: Validators.validateIdCard,
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9Xx]')),
                      ],
                      enabled: widget.person == null, 
                    ),
                    _buildTextField(
                      controller: _nameController,
                      label: '姓名 *',
                      validator: Validators.validateName,
                    ),
                    _buildTextField(
                      controller: _huHaoController,
                      label: '户号',
                      enabled: widget.initialHuHao == null, 
                    ),
                    _buildTextField(
                      controller: _relationController,
                      label: '与户主关系',
                    ),
                    _buildDropdown(
                      value: _isDead,
                      label: '是否死亡',
                      items: const ['', '是', '否'],
                      onChanged: (value) {
                        setState(() {
                          _isDead = value;
                        });
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  
                  _buildSection('联系信息', [
                    _buildTextField(
                      controller: _phoneController,
                      label: '电话',
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: '地址',
                      validator: Validators.validateAddress,
                      maxLines: 2,
                    ),
                    _buildTextField(
                      controller: _groupNameController,
                      label: '小组',
                      maxLines: 1,
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  
                  _buildSection('社会保障', [
                    _buildDropdown(
                      value: _poorType,
                      label: '脱贫户或监测户',
                      items: const ['', '脱贫户', '脱贫不稳定户', '突发严重困难户', '边缘易致贫户'],
                      onChanged: (value) {
                        setState(() {
                          _poorType = value;
                        });
                      },
                    ),
                    _buildDropdown(
                      value: _disability,
                      label: '残疾',
                      items: const ['', '是', '否'],
                      onChanged: (value) {
                        setState(() {
                          _disability = value;
                          if (value != '是') {
                            _disabilityType = null;
                            _disLevel = null;
                          }
                        });
                      },
                    ),
                    if (_disability == '是') ...[
                      _buildDropdown(
                        value: _disabilityType,
                        label: '残疾类型',
                        items: const ['', '视力残疾', '听力残疾', '言语残疾', '肢体残疾', '智力残疾', '精神残疾', '多重残疾'],
                        onChanged: (value) {
                          setState(() {
                            _disabilityType = value;
                          });
                        },
                      ),
                      _buildDropdown(
                        value: _disLevel,
                        label: '残疾等级',
                        items: const ['', '一级', '二级', '三级', '四级'],
                        onChanged: (value) {
                          setState(() {
                            _disLevel = value;
                          });
                        },
                      ),
                    ],
                    // 低保口径统一为 6 值（与服务端 statistics.py 对齐），并对库中未知历史值做兜底：
                    // 下拉 value 回落到 ''（请选择），同时只读提示历史原值，避免 Debug 断言崩溃；
                    // 用户未重新选择时 _dibao 仍保留原始历史值，保存不丢数据。
                    Builder(builder: (_) {
                      const dibaoItems = [
                        '',
                        '是',
                        '否',
                        '低保边缘家庭',
                        '特困家庭',
                        '最低生活保障家庭',
                        '最低生活保障边缘家庭',
                        '单人保家庭',
                      ];
                      final dibaoRaw = _dibao ?? '';
                      final dibaoKnown =
                          dibaoRaw.isEmpty || dibaoItems.contains(dibaoRaw);
                      final dibaoValue = dibaoKnown ? dibaoRaw : '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdown(
                            value: dibaoValue,
                            label: '低保',
                            items: dibaoItems,
                            onChanged: (value) {
                              setState(() {
                                _dibao = value;
                              });
                            },
                          ),
                          if (!dibaoKnown)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16, left: 4),
                              child: Text(
                                '历史值：$dibaoRaw（不在标准选项中，已保留原值，请重新选择以更新）',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange.shade700),
                              ),
                            ),
                        ],
                      );
                    }),
                    _buildDropdown(
                      value: _jisheng,
                      label: '是否计生家庭',
                      items: const ['', '是', '否'],
                      onChanged: (value) {
                        setState(() {
                          _jisheng = value;
                        });
                      },
                    ),
                    _buildDropdown(
                      value: _tekun,
                      label: '是否特困供养',
                      items: const ['', '是', '否'],
                      onChanged: (value) {
                        setState(() {
                          _tekun = value;
                          if (value != '是') {
                            _tekunType = null;
                          }
                        });
                      },
                    ),
                    if (_tekun == '是') ...[
                      _buildDropdown(
                        value: _tekunType,
                        label: '供养类型',
                        items: const ['', '集中供养', '散居特困'],
                        onChanged: (value) {
                          setState(() {
                            _tekunType = value;
                          });
                        },
                      ),
                    ],
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  
                  _buildSection('社保卡信息', [
                    _buildTextField(
                      controller: _socialCard1Controller,
                      label: '社保卡号1',
                      validator: Validators.validateSocialCard,
                    ),
                    _buildTextField(
                      controller: _socialCard2Controller,
                      label: '社保卡号2（自动回填）',
                      readOnly: true,
                    ),
                    _buildTextField(
                      controller: _socialCard3Controller,
                      label: '社保卡号3（自动回填）',
                      readOnly: true,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  
                  _buildSection('就读信息', [
                    _buildTextField(
                      controller: _schoolNameController,
                      label: '学校名称',
                    ),
                    _buildGradeDropdown(),
                    _buildTextField(
                      controller: _classNameController,
                      label: '班级',
                    ),
                    _buildTextField(
                      controller: _guardianController,
                      label: '监护人',
                    ),
                    _buildTextField(
                      controller: _guardianPhoneController,
                      label: '监护人电话',
                      keyboardType: TextInputType.phone,
                    ),
                    _buildDropdown(
                      value: _isLeftBehind,
                      label: '是否留守儿童',
                      items: const ['', '是', '否'],
                      onChanged: (value) {
                        setState(() {
                          _isLeftBehind = value;
                        });
                      },
                    ),
                    _buildDropdown(
                      value: _studentStatus,
                      label: '学生状态',
                      items: const ['', '在读', '休学', '辍学', '毕业'],
                      onChanged: (value) {
                        setState(() {
                          _studentStatus = value;
                        });
                      },
                    ),
                    _buildTextField(
                      controller: _enrollmentDateController,
                      label: '入学日期',
                      hintText: '自动计算，如：2023-09-01',
                    ),
                    _buildTextField(
                      controller: _graduationDateController,
                      label: '毕业时间',
                      hintText: '自动计算，如：2029-06-30',
                    ),
                  ]),

                  const SizedBox(height: 24),

                  
                  _buildSection('其他信息', [
                    _buildTextField(
                      controller: _landAreaController,
                      label: '土地面积（亩）',
                      validator: Validators.validateLandArea,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    _buildTextField(
                      controller: _localWelfareForestAreaController,
                      label: '地方公益林（亩）',
                      validator: Validators.validateLocalWelfareForestArea,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    _buildTextField(
                      controller: _nationalWelfareForestAreaController,
                      label: '国家公益林（亩）',
                      validator: Validators.validateNationalWelfareForestArea,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    _buildTextField(
                      controller: _commercialForestAreaController,
                      label: '非国有天然商品林（亩）',
                      validator: Validators.validateCommercialForestArea,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    _buildTextField(
                      controller: _remarkController,
                      label: '备注',
                      validator: Validators.validateRemark,
                      maxLines: 3,
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
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
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool enabled = true,
    bool readOnly = false,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
          filled: !enabled,
        ),
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        enabled: enabled,
      ),
    );
  }
  
  Widget _buildGradeDropdown() {
    final value = _grade != null && _grade!.isEmpty ? null : _grade;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        menuMaxHeight: 300,
        decoration: const InputDecoration(
          labelText: '年级',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('请选择')),
          ..._gradeOptions.entries.map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value),
          )),
        ],
        onChanged: (v) {
          setState(() {
            _grade = v;
          });
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value?.isEmpty == true ? null : value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        menuMaxHeight: 300,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item.isEmpty ? null : item,
            child: Text(item.isEmpty ? '请选择' : item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
