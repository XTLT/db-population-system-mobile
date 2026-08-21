import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../api/student_api.dart';
import 'student_edit_page.dart';

class StudentDetailPage extends StatefulWidget {
  final String idCard;
  
  const StudentDetailPage({super.key, required this.idCard});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  Student? _student;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      
      final data = await StudentApi.getStudent(widget.idCard);
      final student = Student.fromJson(data);

      setState(() {
        _student = student;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_student?.displayName ?? '学生详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _student == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentEditPage(student: _student),
                      ),
                    );
                    
                    if (result == true) {
                      _loadData();
                    }
                  },
          ),
        ],
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
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (_student == null) {
      return const Center(child: Text('无数据'));
    }
    
    final student = _student!;
    
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
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(
                      Icons.school,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (student.grade != null)
                              Chip(
                                label: Text(student.grade!),
                                backgroundColor: Colors.green.shade100,
                              ),
                            if (student.studentStatus != null) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(student.studentStatus!),
                                backgroundColor: Colors.orange.shade100,
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
          
          
          _buildInfoSection('学校信息', [
            _buildInfoItem('学校名称', student.schoolName),
            _buildInfoItem('年级', student.grade),
            _buildInfoItem('班级', student.className),
            _buildInfoItem('学生状态', student.studentStatus),
            _buildInfoItem('入学日期', student.enrollmentDate),
          ]),
          
          
          _buildInfoSection('监护人信息', [
            _buildInfoItem('监护人', student.guardian),
            _buildInfoItem('监护人电话', student.guardianPhone),
            _buildInfoItem('是否留守儿童', student.isLeftBehind),
          ]),
          
          
          _buildInfoSection('个人信息', [
            _buildInfoItem('身份证号', student.idCard),
          ]),
        ],
      ),
    );
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
  
  Widget _buildInfoItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
