import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/person.dart';
import '../../api/person_api.dart';
import '../../utils/validators.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_data_service.dart';

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
  late TextEditingController _relationController;
  late TextEditingController _phoneController;
  late TextEditingController _remarkController;
  late TextEditingController _landAreaController;
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
  
  String? _grade;
  String? _isLeftBehind;
  String? _studentStatus;
  
  bool _isLoading = false;
  bool _autoFillFromIdCard = false;
  String? _landAreaChangeReason; 
  
  @override
  void initState() {
    super.initState();
    
    
    _idCardController = TextEditingController(text: widget.person?.idCard ?? '');
    _nameController = TextEditingController(text: widget.person?.name ?? '');
    _huHaoController = TextEditingController(
      text: widget.person?.huHao ?? widget.initialHuHao ?? ''
    );
    _addressController = TextEditingController(text: widget.person?.address ?? '');
    _relationController = TextEditingController(text: widget.person?.relation ?? '');
    _phoneController = TextEditingController(text: widget.person?.phone ?? '');
    _remarkController = TextEditingController(text: widget.person?.remark ?? '');
    _landAreaController = TextEditingController(text: widget.person?.landArea ?? '');
    _socialCard1Controller = TextEditingController(text: widget.person?.socialCard1 ?? '');
    _socialCard2Controller = TextEditingController(text: widget.person?.socialCard2 ?? '');
    _socialCard3Controller = TextEditingController(text: widget.person?.socialCard3 ?? '');

    
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
    
    _grade = widget.person?.education?.grade;
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
    _relationController.dispose();
    _phoneController.dispose();
    _remarkController.dispose();
    _landAreaController.dispose();
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
      '一年级': 6, '二年级': 5, '三年级': 4, '四年级': 3, '五年级': 2, '六年级': 1,
      '七年级': 3, '八年级': 2, '九年级': 1,
      '高一': 3, '高二': 2, '高三': 1,
      '1': 6, '2': 5, '3': 4, '4': 3, '5': 2, '6': 1,
      '7': 3, '8': 2, '9': 1,
      '10': 3, '11': 2, '12': 1,
    };

    
    final gradeToOffset = {
      '一年级': 0, '二年级': 1, '三年级': 2, '四年级': 3, '五年级': 4, '六年级': 5,
      '七年级': 0, '八年级': 1, '九年级': 2,
      '高一': 0, '高二': 1, '高三': 2,
      '1': 0, '2': 1, '3': 2, '4': 3, '5': 4, '6': 5,
      '7': 0, '8': 1, '9': 2,
      '10': 0, '11': 1, '12': 2,
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
        enrollmentDate = '$enrollmentYear-09';
      }

      
      if (graduationDate.isEmpty) {
        final totalYears = gradeToYears[_grade] ?? 0;
        if (totalYears > 0) {
          
          
          final gradYear = enrollmentYear + totalYears;
          graduationDate = '$gradYear-06';
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
  
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    
    final newLandArea = _landAreaController.text.trim();
    final oldLandArea = widget.person?.landArea ?? '';
    
    
    if (widget.person != null && 
        newLandArea != oldLandArea && 
        oldLandArea.isNotEmpty) {
      final reason = await _showLandAreaChangeDialog();
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
        'social_card1': _socialCard1Controller.text.trim(),
        'social_card2': _socialCard2Controller.text.trim(),
        'social_card3': _socialCard3Controller.text.trim(),
        'land_area': newLandArea,
        'land_area_change_reason': _landAreaChangeReason ?? '',
      };

      debugPrint('========== 保存数据 ==========');
      debugPrint('土地面积: $newLandArea');
      debugPrint('土地面积变更原因: $_landAreaChangeReason');
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
                    _buildDropdown(
                      value: _dibao,
                      label: '低保',
                      items: const ['', '是', '否', '低保边缘家庭', '特困家庭'],
                      onChanged: (value) {
                        setState(() {
                          _dibao = value;
                        });
                      },
                    ),
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
                      label: '社保卡号2',
                      validator: Validators.validateSocialCard,
                    ),
                    _buildTextField(
                      controller: _socialCard3Controller,
                      label: '社保卡号3',
                      validator: Validators.validateSocialCard,
                    ),
                  ]),

                  const SizedBox(height: 24),

                  
                  _buildSection('就读信息', [
                    _buildTextField(
                      controller: _schoolNameController,
                      label: '学校名称',
                    ),
                    _buildDropdown(
                      value: _grade,
                      label: '年级',
                      items: const ['', '一年级', '二年级', '三年级', '四年级', '五年级', '六年级', '七年级', '八年级', '九年级', '高一', '高二', '高三'],
                      onChanged: (value) {
                        setState(() {
                          _grade = value;
                        });
                      },
                    ),
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
                      hintText: '自动计算，如：2023-09',
                    ),
                    _buildTextField(
                      controller: _graduationDateController,
                      label: '毕业时间',
                      hintText: '自动计算，如：2029-06',
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
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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
