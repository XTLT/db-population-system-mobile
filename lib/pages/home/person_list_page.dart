import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../api/person_api.dart';
import '../../api/batch_operation_api.dart';
import '../../services/offline_data_service.dart';
import '../person/person_detail_page.dart';
import '../search/advanced_search_page.dart';

class PersonListPage extends StatefulWidget {
  const PersonListPage({super.key});

  @override
  State<PersonListPage> createState() => _PersonListPageState();
}

class _PersonListPageState extends State<PersonListPage> {
  final _searchController = TextEditingController();
  List<Person> _persons = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  bool _isSelectionMode = false;
  Set<String> _selectedIds = {};
  
  String? _selectedField;
  String? _newValue;
  final _valueController = TextEditingController();
  
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
  
  void _batchEdit() {
    _selectedField = null;
    _newValue = null;
    _valueController.clear();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('批量编辑'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '将修改 ${_selectedIds.length} 个选中项',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedField,
                  decoration: const InputDecoration(
                    labelText: '选择要修改的字段',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'is_dead',
                      child: Text('是否去世'),
                    ),
                    DropdownMenuItem(
                      value: 'dibao',
                      child: Text('低保类别'),
                    ),
                    DropdownMenuItem(
                      value: 'disability',
                      child: Text('残疾情况'),
                    ),
                    DropdownMenuItem(
                      value: 'dis_level',
                      child: Text('残疾等级'),
                    ),
                    DropdownMenuItem(
                      value: 'poor_type',
                      child: Text('贫困户类型'),
                    ),
                    DropdownMenuItem(
                      value: 'jisheng',
                      child: Text('计生情况'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedField = value;
                      _newValue = null;
                      _valueController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedField != null)
                  _buildValueInput(setState),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _selectedField != null && _newValue != null
                  ? () => _executeBatchEdit(context)
                  : null,
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildValueInput(StateSetter setState) {
    if (_selectedField == 'is_dead') {
      return DropdownButtonFormField<String>(
        value: _newValue,
        decoration: const InputDecoration(
          labelText: '新值',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: '是', child: Text('是')),
          DropdownMenuItem(value: '否', child: Text('否')),
        ],
        onChanged: (value) {
          setState(() {
            _newValue = value;
          });
        },
      );
    } else {
      return TextField(
        controller: _valueController,
        decoration: const InputDecoration(
          labelText: '新值',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _newValue = value.trim().isEmpty ? null : value.trim();
          });
        },
      );
    }
  }
  
  Future<void> _executeBatchEdit(BuildContext dialogContext) async {
    Navigator.pop(dialogContext);
    
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final updates = <String, dynamic>{};
      updates[_selectedField!] = _newValue!;
      
      final result = await BatchOperationApi.batchUpdatePersons(
        _selectedIds.toList(),
        updates,
      );
      
      
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功更新 ${result['updated']} 条记录')),
        );
        _toggleSelectionMode();
        _loadPersons();
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
  
  void _loadPersons() {
    
    if (_searchController.text.trim().isNotEmpty) {
      _search();
    } else {
      setState(() {
        _persons = [];
      });
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
      final result = await BatchOperationApi.batchDeletePersons(
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
        _loadPersons();
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
  
  Future<void> _search() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入姓名进行查询')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _persons = [];
    });
    
    try {
      final results = await PersonApi.searchByName(_searchController.text.trim());
      
      setState(() {
        _persons = results;
        _isLoading = false;
      });

      if (results.isNotEmpty) {
        await OfflineDataService().cachePersonList(
          results.map((p) => p.toJson()).toList(),
        );
      }
      
      if (results.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到相关记录')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('查询失败: $e')),
        );
      }
    }
  }
  
  Future<void> _navigateToAdvancedSearch() async {
    final results = await Navigator.push<List<Person>>(
      context,
      MaterialPageRoute(
        builder: (_) => const AdvancedSearchPage(),
      ),
    );
    
    if (results != null && mounted) {
      setState(() {
        _persons = results;
        _isSelectionMode = false;
        _selectedIds.clear();
      });
      
      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到符合条件的记录')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('找到 ${results.length} 条记录')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _valueController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '已选择 ${_selectedIds.length} 项' 
            : '人员列表'),
        actions: [
          if (!_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _navigateToAdvancedSearch,
              tooltip: '高级搜索',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '姓名查询',
                hintText: '请输入姓名',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _search,
                ),
              ),
              onSubmitted: (_) => _search(),
              enabled: !_isLoading,
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _persons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '请输入姓名进行查询',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _persons.length,
                        itemBuilder: (context, index) {
                          final person = _persons[index];
                          final personId = person.idCard ?? '';
                          final isSelected = _selectedIds.contains(personId);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: personId.isNotEmpty 
                                          ? (_) => _toggleSelection(personId)
                                          : null,
                                    )
                                  : CircleAvatar(
                                      child: Text(
                                        person.name?.substring(0, 1) ?? '?',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                              title: Text(
                                person.displayName,
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
                                    '身份证: ${person.idCard ?? "未知"}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      if (person.age != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            person.displayAge,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      if (person.isDeceased) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '已死亡',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (person.relation != null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${person.relation})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: _isSelectionMode 
                                  ? null 
                                  : const Icon(Icons.arrow_forward),
                              onTap: _isSelectionMode
                                  ? personId.isNotEmpty 
                                      ? () => _toggleSelection(personId)
                                      : null
                                  : () {
                                      if (person.idCard != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PersonDetailPage(
                                              idCard: person.idCard!,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              onLongPress: !_isSelectionMode && personId.isNotEmpty
                                  ? () {
                                      setState(() {
                                        _isSelectionMode = true;
                                        _selectedIds.add(personId);
                                      });
                                    }
                                  : null,
                            ),
                          );
                        },
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
                    onPressed: _selectedIds.length < _persons.length
                        ? () => setState(() => _selectedIds = _persons
                            .map((p) => p.idCard ?? '')
                            .where((id) => id.isNotEmpty)
                            .toSet())
                        : null,
                    child: const Text('全选'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _selectedIds.length > 10 
                        ? null 
                        : _batchEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('批量编辑'),
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
      ),
    );
  }
}
