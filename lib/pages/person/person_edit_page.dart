import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/person.dart';
import '../../api/person_api.dart';
import '../../utils/validators.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_data_service.dart';
import '../../api/api_client.dart';
import 'person_change_reason_dialog.dart';
import 'person_form_data.dart';
import 'person_form_widgets.dart';

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
  String? _deathDate;
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

  // 年级字典与归一化规则见 person_form_data.dart（纯数据，可单测）

  // 社保卡号2/3 仅由补贴导入自动回填，展示为 卡号+来源（如 6217********（低保202606））
  String _socialCardDisplay(String? card, String? source) {
    if (card == null || card.isEmpty || card == '无') return '';
    final s = (source != null && source.isNotEmpty) ? '（$source）' : '';
    return '$card$s';
  }
  
  bool _isLoading = false;
  bool _autoFillFromIdCard = false;
  // 同户信息：用于提示"本户已有户主"，避免重复设户主被服务端拒绝
  int _householdMemberCount = 0;
  String? _householdHeadName;
  String? _householdHeadIdCard;
  bool _householdChecked = false;
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
    _deathDate = widget.person?.deathDate;
    _poorType = widget.person?.poorType;
    _disability = widget.person?.disability;
    _disabilityType = widget.person?.disabilityType;
    _disLevel = widget.person?.disLevel;
    _dibao = widget.person?.dibao;
    _jisheng = widget.person?.jisheng;
    _tekun = widget.person?.tekun;
    _tekunType = widget.person?.tekunType;
    
    _grade = normalizeGrade(widget.person?.education?.grade);
    _isLeftBehind = widget.person?.education?.isLeftBehind;
    _studentStatus = widget.person?.education?.studentStatus;
    
    
    _idCardController.addListener(_onIdCardChanged);
    
    // 新增人员时：自动带出同户户号成员的地址和小组（与 desktop 端行为一致）
    final huhao = _huHaoController.text.trim();
    if (huhao.isNotEmpty) {
      // 编辑时只查本户情况用于提示，不覆盖已有地址/小组
      _autoFillAddressAndGroup(huhao, fillFields: widget.person == null);
    }
    // 改户号时重新查一次
    _huHaoController.addListener(_onHuHaoChanged);
  }

  Timer? _huHaoDebounce;

  void _onHuHaoChanged() {
    _huHaoDebounce?.cancel();
    final huhao = _huHaoController.text.trim();

    // 换了户号立即撤掉上一个户的提示，等新户查询结果回来再显示，
    // 否则会把"本户已有户主 X"错挂到另一个户号下面。
    if (_householdChecked) {
      setState(() {
        _householdChecked = false;
        _householdMemberCount = 0;
        _householdHeadName = null;
        _householdHeadIdCard = null;
      });
    }
    if (huhao.isEmpty) return;

    _huHaoDebounce = Timer(const Duration(milliseconds: 400), () {
      final current = _huHaoController.text.trim();
      if (current.isEmpty) return;
      // 编辑时只提示本户户主情况，不覆盖已有地址/小组
      _autoFillAddressAndGroup(current, fillFields: widget.person == null);
    });
  }

  // 查询同户户号成员：记录人数/户主用于提示；fillFields=true（新增人员）时
  // 顺带把地址和小组带出来，只填空值，不覆盖用户已输入内容。
  Future<void> _autoFillAddressAndGroup(
    String huHao, {
    bool fillFields = true,
  }) async {
    try {
      final members = await PersonApi.getFamilyMembers(huHao);
      if (!mounted) return;
      // 连改两次户号时，先返回的旧查询不能覆盖当前户的提示
      if (_huHaoController.text.trim() != huHao) return;

      String? headName;
      String? headIdCard;
      for (final m in members) {
        if ((m.relation ?? '').trim() == '户主') {
          headName = m.name;
          headIdCard = m.idCard;
          break;
        }
      }
      setState(() {
        _householdChecked = true;
        _householdMemberCount = members.length;
        _householdHeadName = headName;
        _householdHeadIdCard = headIdCard;
      });

      if (!fillFields) return;
      for (final m in members) {
        final addr = (m.address ?? '').trim();
        if (addr.isNotEmpty) {
          if (_addressController.text.trim().isEmpty) {
            _addressController.text = addr;
          }
          final grp = (m.groupName ?? '').trim();
          if (grp.isNotEmpty && _groupNameController.text.trim().isEmpty) {
            _groupNameController.text = grp;
          }
          return;
        }
      }
    } catch (_) {
      // 查询失败静默（离线等场景不阻塞表单）
    }
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
    _huHaoDebounce?.cancel();
    _idCardController.dispose();
    _nameController.dispose();
    _huHaoController.removeListener(_onHuHaoChanged);
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
  
  
  // 入学/毕业日期推算见 person_form_data.dart（纯函数，可单测）

  /// 就读信息 payload：没有学校/年级/班级时返回 null（不提交空记录）。
  ///
  /// 在线保存和离线草稿共用，避免断网新增学生时丢掉就读信息。
  Map<String, dynamic>? _buildEducationPayload() {
    final hasEducation = _schoolNameController.text.trim().isNotEmpty ||
        _grade != null ||
        _classNameController.text.trim().isNotEmpty;
    if (!hasEducation) return null;

    final dates = calculateEnrollmentAndGraduation(
      grade: _grade,
      enrollmentDate: _enrollmentDateController.text.trim(),
      graduationDate: _graduationDateController.text.trim(),
    );
    return {
      'school_name': _schoolNameController.text.trim(),
      'grade': _grade ?? '',
      'class_name': _classNameController.text.trim(),
      'guardian': _guardianController.text.trim(),
      'guardian_phone': _guardianPhoneController.text.trim(),
      'is_left_behind': _isLeftBehind ?? '否',
      'student_status': _studentStatus ?? '在读',
      'enrollment_date':
          dates['enrollment_date'] ?? _enrollmentDateController.text.trim(),
      'graduation_date':
          dates['graduation_date'] ?? _graduationDateController.text.trim(),
    };
  }

  /// 离线转存：把就读信息挂在 `__education` 下随人员 payload 一起入队，
  /// 同步时由 SyncService 拆出来单独提交。
  Future<void> _saveOffline(Map<String, dynamic> data) async {
    final education = _buildEducationPayload();
    final offlineData = <String, dynamic>{...data};
    if (education != null) {
      offlineData['__education'] = education;
    }
    await OfflineDataService().savePersonOffline(
      offlineData,
      isCreate: widget.person == null,
      // 记录进入编辑页时服务端的版本，同步时据此做真实冲突检测
      baseUpdatedAt: widget.person?.updatedAt,
    );
  }

  Future<String?> _showLandAreaChangeDialog() async {
    final reason = await showPersonChangeReasonDialog(
      context: context,
      title: '土地面积变更',
      label: '土地面积',
      oldValue: widget.person?.landArea ?? '',
      newValue: _landAreaController.text.trim(),
      hint: '例如：土地流转、测量修正等',
    );
    if (reason != null) {
      _landAreaChangeReason = reason;
    }
    return reason;
  }

  Future<String?> _showLocalWelfareForestAreaChangeDialog() async {
    final reason = await showPersonChangeReasonDialog(
      context: context,
      title: '地方公益林变更',
      label: '地方公益林',
      oldValue: widget.person?.localWelfareForestArea ?? '',
      newValue: _localWelfareForestAreaController.text.trim(),
      hint: '例如：林地流转、测量修正等',
    );
    if (reason != null) {
      _localWelfareForestChangeReason = reason;
    }
    return reason;
  }

  Future<String?> _showNationalWelfareForestAreaChangeDialog() async {
    final reason = await showPersonChangeReasonDialog(
      context: context,
      title: '国家公益林变更',
      label: '国家公益林',
      oldValue: widget.person?.nationalWelfareForestArea ?? '',
      newValue: _nationalWelfareForestAreaController.text.trim(),
      hint: '例如：林地流转、测量修正等',
    );
    if (reason != null) {
      _nationalWelfareForestChangeReason = reason;
    }
    return reason;
  }

  Future<String?> _showCommercialForestAreaChangeDialog() async {
    final reason = await showPersonChangeReasonDialog(
      context: context,
      title: '非国有天然商品林变更',
      label: '非国有天然商品林',
      oldValue: widget.person?.commercialForestArea ?? '',
      newValue: _commercialForestAreaController.text.trim(),
      hint: '例如：林地流转、测量修正等',
    );
    if (reason != null) {
      _commercialForestChangeReason = reason;
    }
    return reason;
  }

  /// 死亡时间：仅在"是否死亡"选"是"后显示，点击选择日期
  Widget _buildDeathDateField() {
    // 存量已死亡人员（原本就是"是"）不强制补录，标签不加星号
    final required = widget.person?.isDead != '是';
    final filled = _deathDate != null && _deathDate!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: _pickDeathDate,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: required ? '死亡时间 *' : '死亡时间',
            hintText: '点击选择日期',
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            filled ? _deathDate! : '未填写',
            style: TextStyle(color: filled ? null : Colors.grey),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeathDate() async {
    final now = DateTime.now();
    var initial = now;
    if (_deathDate != null && _deathDate!.isNotEmpty) {
      initial = DateTime.tryParse(_deathDate!) ?? now;
    }
    if (initial.isAfter(now)) initial = now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '选择死亡日期',
    );
    if (picked != null) {
      setState(() {
        _deathDate = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  /// 人员提交 payload：在线提交与离线草稿共用同一份字段定义。
  Map<String, dynamic> _buildPersonPayload() {
    return {
      'id_card': _idCardController.text.trim(),
      'name': _nameController.text.trim(),
      'hu_hao': _huHaoController.text.trim(),
      'address': _addressController.text.trim(),
      'group_name': _groupNameController.text.trim(),
      'relation': _relationController.text.trim(),
      'phone': _phoneController.text.trim(),
      'is_dead': _isDead,
      'death_date': _deathDate ?? '',
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
      'land_area': _landAreaController.text.trim(),
      'land_area_change_reason': _landAreaChangeReason ?? '',
      'local_welfare_forest_area':
          _localWelfareForestAreaController.text.trim(),
      'local_welfare_forest_change_reason':
          _localWelfareForestChangeReason ?? '',
      'national_welfare_forest_area':
          _nationalWelfareForestAreaController.text.trim(),
      'national_welfare_forest_change_reason':
          _nationalWelfareForestChangeReason ?? '',
      'commercial_forest_area': _commercialForestAreaController.text.trim(),
      'commercial_forest_change_reason': _commercialForestChangeReason ?? '',
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 本户已有别的户主时，选"户主"必然被服务端拒绝，提前拦下
    final selfIdCard = widget.person?.idCard ?? '';
    final hasOtherHead = _householdChecked &&
        (_householdHeadIdCard ?? '').isNotEmpty &&
        _householdHeadIdCard != selfIdCard;
    if (hasOtherHead && _relationController.text.trim() == '户主') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '本户已有户主 ${_householdHeadName ?? ''}，请改选其他关系再保存',
          ),
        ),
      );
      return;
    }

    // 只在"由非死亡改为死亡"时要求填死亡时间；已是死亡的人员改其他信息不强制
    if (_isDead == '是' &&
        widget.person?.isDead != '是' &&
        (_deathDate == null || _deathDate!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('改为死亡时必须填写死亡时间')),
      );
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

    // 先构造 payload：离线转存与在线提交共用同一份数据
    final data = _buildPersonPayload();

    setState(() {
      _isLoading = true;
    });

    try {
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
        
        await _saveOffline(data);

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
      String personId = '';
      bool educationFailed = false;
      if (widget.person == null) {
        success = await PersonApi.addPerson(data);
        // 新增时服务端返回的 person 没有回传 id，用身份证号继续提交就读信息
        personId = (data['id_card'] ?? '').toString();
      } else {
        final idCard = widget.person?.idCard ?? '';
        if (idCard.isEmpty) {
          throw Exception('人员身份证号为空，无法更新');
        }
        // 带上打开编辑页时的 updated_at：服务端发现期间被改过会返回 409，
        // 避免"后保存的人静默覆盖前一个人"。
        final baseUpdatedAt = widget.person?.updatedAt;
        if (baseUpdatedAt != null && baseUpdatedAt.isNotEmpty) {
          data['updated_at'] = baseUpdatedAt;
        }
        success = await PersonApi.updatePerson(
          idCard,
          data,
        );
        final pid = widget.person?.id ?? '';
        personId = pid.isEmpty ? idCard : pid;
      }

      final education = _buildEducationPayload();
      if (success && personId.isNotEmpty && education != null) {
        try {
          await PersonApi.updateEducation(personId, education);
        } catch (e) {
          debugPrint('保存就读信息失败: $e');
          educationFailed = true;
        }
      }

      if (success && mounted) {
        debugPrint('========== 保存成功，返回 true ==========');
        // 清除统计缓存，确保统计数据及时更新
        ApiClient().invalidatePath('GET', '/api/statistics');
        ApiClient().invalidatePath('GET', '/api/students/statistics');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(educationFailed
                ? '人员已保存，但就读信息未同步，请稍后在编辑页补填'
                : (widget.person == null ? '添加成功' : '保存成功')),
            duration: Duration(seconds: educationFailed ? 4 : 2),
          ),
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
    } on PersonConflictException catch (e) {
      // 保存期间别人改过这条记录：不覆盖、不入队，让用户回详情页刷新后再改
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败：${e.message}。请返回详情刷新后重新编辑'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on OfflineQueueException {
      // 在线但服务器不可达/超时：保留草稿，避免用户白填一遍
      await _saveOffline(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('网络异常，已保存到离线队列，联网后自动提交'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true);
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
  
  /// 新增页有姓名/身份证时返回要确认，避免误触返回丢掉刚填的一整页。
  bool get _hasUnsavedInput =>
      widget.person == null &&
      (_nameController.text.trim().isNotEmpty ||
          _idCardController.text.trim().isNotEmpty);

  Future<void> _onBackPressed() async {
    if (_isLoading) return; // 提交中不让退出，避免已保存却看不出结果
    if (!_hasUnsavedInput) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('放弃已填写的内容？'),
        content: const Text('还没保存，返回后已填内容会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('继续填写'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('放弃'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
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
                  _buildHouseholdHint(),
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
                    _buildRelationDropdown(),
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
                    if (_isDead == '是') _buildDeathDateField(),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  
                  _buildSection('联系信息', [
                    _buildTextField(
                      controller: _phoneController,
                      label: '电话',
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
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
                      validator: Validators.validatePhone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                      ],
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
  
  /// 展示同户情况：已有户主时提前拦住"关系选户主"的重复提交；
  /// 编辑本人时区分"您就是本户户主"，避免误报。
  Widget _buildHouseholdHint() {
    if (!_householdChecked) {
      return const SizedBox.shrink();
    }
    final huHao = _huHaoController.text.trim();
    if (huHao.isEmpty) return const SizedBox.shrink();

    final head = _householdHeadName;
    final relation = _relationController.text.trim();
    final selfIdCard = widget.person?.idCard ?? '';
    final isSelfHead = head != null &&
        head.isNotEmpty &&
        selfIdCard.isNotEmpty &&
        _householdHeadIdCard == selfIdCard;
    String text;
    Color color;
    IconData icon;

    if (_householdMemberCount == 0) {
      text = '户号 $huHao 暂无成员，将按新户录入';
      color = Colors.blueGrey;
      icon = Icons.info_outline;
    } else if (isSelfHead) {
      if (relation.isNotEmpty && relation != '户主') {
        text = '本户已有 $_householdMemberCount 人，您是本户户主。'
            '改选其他关系会取消本户户主';
        color = Colors.orange.shade800;
      } else {
        text = '本户已有 $_householdMemberCount 人，您是本户户主';
        color = Colors.blueGrey;
      }
      icon = Icons.info_outline;
    } else if (head != null && head.isNotEmpty) {
      if (relation == '户主') {
        text = '本户已有 $_householdMemberCount 人，户主是 $head。'
            '每户只能有一个户主，请改选其他关系，否则保存会被拒绝';
        color = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
      } else {
        text = '本户已有 $_householdMemberCount 人，户主：$head';
        color = Colors.blueGrey;
        icon = Icons.info_outline;
      }
    } else {
      text = '本户已有 $_householdMemberCount 人，暂未设户主';
      color = Colors.orange.shade800;
      icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) =>
      PersonFormWidgets.section(title, children);

  Widget _buildRelationDropdown() => PersonFormWidgets.relationDropdown(
        current: _relationController.text.trim(),
        onChanged: (v) {
          setState(() {
            _relationController.text = v ?? '';
          });
        },
      );

  Widget _buildGradeDropdown() => PersonFormWidgets.gradeDropdown(
        value: _grade,
        onChanged: (v) {
          setState(() {
            _grade = v;
          });
        },
      );

  Widget _buildDropdown({
    required String? value,
    required String label,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      PersonFormWidgets.dropdown(
        value: value,
        label: label,
        items: items,
        onChanged: onChanged,
      );

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
  }) =>
      PersonFormWidgets.textField(
        controller: controller,
        label: label,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        enabled: enabled,
        readOnly: readOnly,
        hintText: hintText,
      );
}
