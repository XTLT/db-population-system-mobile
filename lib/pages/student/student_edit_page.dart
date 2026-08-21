import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../api/student_api.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_data_service.dart';

class StudentEditPage extends StatefulWidget {
  final Student? student;
  
  const StudentEditPage({super.key, this.student});

  @override
  State<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends State<StudentEditPage> {
  final _formKey = GlobalKey<FormState>();
  
  
  late TextEditingController _idCardController;
  late TextEditingController _schoolNameController;
  late TextEditingController _classNameController;
  late TextEditingController _guardianController;
  late TextEditingController _guardianPhoneController;
  late TextEditingController _enrollmentDateController;
  
  
  String? _grade;
  String? _studentStatus;
  String? _isLeftBehind;
  
  bool _isLoading = false;
  
  
  final Map<String, String> _gradeOptions = {
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
  
  
  final List<String> _statusOptions = [
    '在读', '留级', '跳级', '休学', '转学', '毕业'
  ];
  
  @override
  void initState() {
    super.initState();
    
    _idCardController = TextEditingController(text: widget.student?.idCard ?? '');
    _schoolNameController = TextEditingController(text: widget.student?.schoolName ?? '');
    _classNameController = TextEditingController(text: widget.student?.className ?? '');
    _guardianController = TextEditingController(text: widget.student?.guardian ?? '');
    _guardianPhoneController = TextEditingController(text: widget.student?.guardianPhone ?? '');
    _enrollmentDateController = TextEditingController(text: widget.student?.enrollmentDate ?? '');
    
    _grade = widget.student?.grade;
    _studentStatus = widget.student?.studentStatus ?? '在读';
    _isLeftBehind = widget.student?.isLeftBehind;
  }
  
  @override
  void dispose() {
    _idCardController.dispose();
    _schoolNameController.dispose();
    _classNameController.dispose();
    _guardianController.dispose();
    _guardianPhoneController.dispose();
    _enrollmentDateController.dispose();
    super.dispose();
  }
  
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'id_card': _idCardController.text.trim(),
        'school_name': _schoolNameController.text.trim(),
        'grade': _grade,
        'class_name': _classNameController.text.trim(),
        'guardian': _guardianController.text.trim(),
        'guardian_phone': _guardianPhoneController.text.trim(),
        'is_left_behind': _isLeftBehind,
        'student_status': _studentStatus,
        'enrollment_date': _enrollmentDateController.text.trim(),
      };

      
      final isConnected = await ConnectivityService().isConnected();

      if (!isConnected) {
        
        await OfflineDataService().saveStudentOffline(data);

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

      
      final idCard = widget.student?.idCard ?? '';
      if (idCard.isEmpty) {
        throw Exception('学生身份证号为空，无法更新');
      }
      final success = await StudentApi.updateStudent(
        idCard,
        data,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.of(context).pop(true);
      } else {
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
        title: Text(widget.student == null ? '新增学生' : '编辑学生信息'),
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
                padding: const EdgeInsets.all(16),
                children: [
                  
                  _buildSection('个人信息', [
                    _buildTextField(
                      controller: _idCardController,
                      label: '身份证号',
                      enabled: false,
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  
                  _buildSection('学校信息', [
                    _buildTextField(
                      controller: _schoolNameController,
                      label: '学校名称',
                    ),
                    _buildGradeDropdown(),
                    _buildTextField(
                      controller: _classNameController,
                      label: '班级',
                    ),
                    _buildDropdown(
                      value: _studentStatus,
                      label: '学生状态',
                      items: _statusOptions,
                      onChanged: (value) {
                        setState(() {
                          _studentStatus = value;
                        });
                      },
                    ),
                    _buildTextField(
                      controller: _enrollmentDateController,
                      label: '入学日期',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  
                  _buildSection('监护人信息', [
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
                      items: const ['是', '否'],
                      onChanged: (value) {
                        setState(() {
                          _isLeftBehind = value;
                        });
                      },
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
    String? hintText,
    TextInputType? keyboardType,
    bool enabled = true,
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
        keyboardType: keyboardType,
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
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildGradeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _grade,
        decoration: const InputDecoration(
          labelText: '年级',
          border: OutlineInputBorder(),
        ),
        items: _gradeOptions.entries.map((entry) {
          return DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _grade = value;
          });
        },
      ),
    );
  }
}
