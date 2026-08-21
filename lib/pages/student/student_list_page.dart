import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../models/student.dart';
import '../../api/student_api.dart';
import '../../api/batch_operation_api.dart';
import '../../utils/pagination_mixin.dart';
import 'student_detail_page.dart';

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _searchController = TextEditingController();
  final _refreshController = RefreshController(initialRefresh: false);
  
  late PaginationHelper<Student> _paginationHelper;
  bool _isSearchMode = false;
  String _searchQuery = '';
  
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};
  
  String? _selectedGrade;
  final _gradeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    _paginationHelper = PaginationHelper<Student>(
      fetchData: _fetchData,
      pageSize: 20,
    );
    
    
    _paginationHelper.refresh(setState);
  }
  
  Future<List<Student>> _fetchData(int page, int pageSize) async {
    if (_isSearchMode) {
      final results = await StudentApi.searchStudents(_searchQuery);
      
      if (page == 0) {
        return results;
      } else {
        return [];
      }
    } else {
      final offset = page * pageSize;
      return await StudentApi.getAllStudents(limit: pageSize, offset: offset);
    }
  }
  
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }
  
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }
  
  void _batchUpdateGrade() {
    _selectedGrade = null;
    _gradeController.clear();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('批量更新年级'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '将修改 ${_selectedIds.length} 个选中项的年级',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: '选择年级',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: '一年级', child: Text('一年级')),
                  DropdownMenuItem(value: '二年级', child: Text('二年级')),
                  DropdownMenuItem(value: '三年级', child: Text('三年级')),
                  DropdownMenuItem(value: '四年级', child: Text('四年级')),
                  DropdownMenuItem(value: '五年级', child: Text('五年级')),
                  DropdownMenuItem(value: '六年级', child: Text('六年级')),
                  DropdownMenuItem(value: '初一', child: Text('初一')),
                  DropdownMenuItem(value: '初二', child: Text('初二')),
                  DropdownMenuItem(value: '初三', child: Text('初三')),
                  DropdownMenuItem(value: '高一', child: Text('高一')),
                  DropdownMenuItem(value: '高二', child: Text('高二')),
                  DropdownMenuItem(value: '高三', child: Text('高三')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGrade = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _selectedGrade != null
                  ? () => _executeBatchUpdateGrade(context)
                  : null,
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _executeBatchUpdateGrade(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final result = await BatchOperationApi.batchUpdateStudents(
        _selectedIds.toList(),
        {'grade': _selectedGrade},
      );
      
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功更新 ${result['updated']} 条记录')),
        );
        _toggleSelectionMode();
        _paginationHelper.refresh(setState);
      }
    } catch (e) {
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量更新失败: $e')),
        );
      }
    }
  }
  
  void _batchDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确定要删除选中的 ${_selectedIds.length} 条记录吗？',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此操作不可撤销，删除后数据将无法恢复！',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeBatchDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _executeBatchDelete() async {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final result = await BatchOperationApi.batchDeleteStudents(
        _selectedIds.toList(),
      );
      
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功删除 ${result['deleted']} 条记录')),
        );
        _toggleSelectionMode();
        _paginationHelper.refresh(setState);
      }
    } catch (e) {
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量删除失败: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    _gradeController.dispose();
    super.dispose();
  }
  
  Future<void> _search() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入姓名进行查询')),
      );
      return;
    }
    
    setState(() {
      _isSearchMode = true;
      _searchQuery = _searchController.text.trim();
    });
    
    await _paginationHelper.refresh(setState);
  }
  
  Future<void> _loadAll() async {
    setState(() {
      _isSearchMode = false;
      _searchQuery = '';
    });
    
    await _paginationHelper.refresh(setState);
  }
  
  Future<void> _onRefresh() async {
    await _paginationHelper.refresh(setState);
    _refreshController.refreshCompleted();
  }
  
  Future<void> _onLoading() async {
    await _paginationHelper.load(setState);
    if (_paginationHelper.hasMore) {
      _refreshController.loadComplete();
    } else {
      _refreshController.loadNoData();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: '姓名查询',
                    hintText: '请输入学生姓名',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _paginationHelper.isLoading ? null : _search,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                  enabled: !_paginationHelper.isLoading,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.list),
                tooltip: '查看全部',
                onPressed: _paginationHelper.isLoading ? null : _loadAll,
              ),
              if (!_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _toggleSelectionMode,
                  tooltip: '选择',
                ),
              if (_isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                  tooltip: '取消',
                ),
            ],
          ),
        ),
        
        
        Expanded(
          child: _paginationHelper.items.isEmpty && !_paginationHelper.isLoading
              ? EmptyDataWidget(
                  message: _isSearchMode 
                      ? '未找到相关记录' 
                      : '暂无学生数据',
                  icon: Icons.school_outlined,
                  onRefresh: () => _paginationHelper.refresh(setState),
                )
              : SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  enablePullUp: _paginationHelper.hasMore,
                  onRefresh: _onRefresh,
                  onLoading: _onLoading,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _paginationHelper.items.length + (_paginationHelper.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      
                      if (index == _paginationHelper.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      
                      final student = _paginationHelper.items[index];
                      return _buildStudentCard(student);
                    },
                  ),
                ),
        ),
        
        
        if (_isSelectionMode && _selectedIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: _selectedIds.length < _paginationHelper.items.length
                      ? () => setState(() => _selectedIds = _paginationHelper.items
                          .map((s) => s.idCard ?? '')
                          .where((id) => id.isNotEmpty)
                          .toSet())
                      : null,
                  child: const Text('全选'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _batchUpdateGrade,
                  icon: const Icon(Icons.edit),
                  label: const Text('批量更新年级'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _batchDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('批量删除'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildStudentCard(Student student) {
    final studentId = student.idCard ?? '';
    final isSelected = _selectedIds.contains(studentId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: studentId.isNotEmpty 
                    ? (_) => _toggleSelection(studentId)
                    : null,
              )
            : CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.school,
                  color: Colors.blue.shade700,
                ),
              ),
        title: Text(
          student.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '学校: ${student.schoolName ?? "未知"}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (student.grade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      student.grade!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                if (student.studentStatus != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      student.studentStatus!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: _isSelectionMode ? null : const Icon(Icons.arrow_forward),
        onTap: _isSelectionMode
            ? studentId.isNotEmpty 
                ? () => _toggleSelection(studentId)
                : null
            : () {
                if (student.idCard != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailPage(idCard: student.idCard!),
                    ),
                  );
                }
              },
        onLongPress: !_isSelectionMode && studentId.isNotEmpty
            ? () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.add(studentId);
                });
              }
            : null,
      ),
    );
  }
}
