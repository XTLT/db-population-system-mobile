import 'package:flutter/material.dart';
import '../../models/person.dart';
import '../../api/person_api.dart';
import '../../services/search_history_service.dart';
import '../../services/saved_filter_service.dart';

class AdvancedSearchPage extends StatefulWidget {
  const AdvancedSearchPage({super.key});

  @override
  State<AdvancedSearchPage> createState() => _AdvancedSearchPageState();
}

class _AdvancedSearchPageState extends State<AdvancedSearchPage> {
  
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();
  final _huHaoController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageMinController = TextEditingController();
  final _ageMaxController = TextEditingController();
  
  
  String? _selectedDisability;
  String? _selectedDibao;
  String? _selectedIsDead;
  
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _searchHistory = [];
  List<Map<String, dynamic>> _savedFilters = [];
  bool _showHistory = true;
  
  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadSavedFilters();
  }
  
  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.getHistory();
    setState(() {
      _searchHistory = history;
    });
  }
  
  Future<void> _loadSavedFilters() async {
    final filters = await SavedFilterService.getFilters();
    setState(() {
      _savedFilters = filters;
    });
  }
  
  void _fillFromHistory(Map<String, dynamic> historyItem) {
    final params = historyItem['params'] as Map<String, dynamic>;
    
    _nameController.text = params['name'] ?? '';
    _idCardController.text = params['idCard'] ?? '';
    _huHaoController.text = params['huHao'] ?? '';
    _addressController.text = params['address'] ?? '';
    _ageMinController.text = params['ageMin'] ?? '';
    _ageMaxController.text = params['ageMax'] ?? '';
    
    setState(() {
      _selectedDisability = params['disability'];
      _selectedDibao = params['dibao'];
      _selectedIsDead = params['isDead'];
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    _huHaoController.dispose();
    _addressController.dispose();
    _ageMinController.dispose();
    _ageMaxController.dispose();
    super.dispose();
  }
  
  void _clearFilters() {
    _nameController.clear();
    _idCardController.clear();
    _huHaoController.clear();
    _addressController.clear();
    _ageMinController.clear();
    _ageMaxController.clear();
    setState(() {
      _selectedDisability = null;
      _selectedDibao = null;
      _selectedIsDead = null;
    });
  }
  
  void _showSaveFilterDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存筛选条件'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '筛选名称',
            hintText: '例如：老年人查询',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入筛选名称')),
                );
                return;
              }
              
              await SavedFilterService.saveFilter(name, {
                'name': _nameController.text,
                'idCard': _idCardController.text,
                'huHao': _huHaoController.text,
                'address': _addressController.text,
                'ageMin': _ageMinController.text,
                'ageMax': _ageMaxController.text,
                'disability': _selectedDisability,
                'dibao': _selectedDibao,
                'isDead': _selectedIsDead,
              });
              
              Navigator.pop(context);
              _loadSavedFilters();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('筛选条件已保存')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _loadSavedFilter(Map<String, dynamic> filterItem) {
    final params = filterItem['params'] as Map<String, dynamic>;
    
    _nameController.text = params['name'] ?? '';
    _idCardController.text = params['idCard'] ?? '';
    _huHaoController.text = params['huHao'] ?? '';
    _addressController.text = params['address'] ?? '';
    _ageMinController.text = params['ageMin'] ?? '';
    _ageMaxController.text = params['ageMax'] ?? '';
    
    setState(() {
      _selectedDisability = params['disability'];
      _selectedDibao = params['dibao'];
      _selectedIsDead = params['isDead'];
    });
  }
  
  void _showSavedFiltersMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '我的筛选',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_savedFilters.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await SavedFilterService.clearFilters();
                      _loadSavedFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('清空全部'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_savedFilters.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('暂无保存的筛选条件', style: TextStyle(color: Colors.grey)),
              )
            else
              ...List.generate(_savedFilters.length, (index) {
                final filter = _savedFilters[index];
                final name = filter['name'] as String;
                final params = filter['params'] as Map<String, dynamic>;
                
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.filter_list),
                  title: Text(name),
                  subtitle: Text(
                    SearchHistoryService.formatSearchParams(params),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await SavedFilterService.deleteFilter(name);
                      _loadSavedFilters();
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    _loadSavedFilter(filter);
                    Navigator.pop(context);
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
  
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final results = await PersonApi.searchAdvanced(
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        idCard: _idCardController.text.isNotEmpty ? _idCardController.text : null,
        huHao: _huHaoController.text.isNotEmpty ? _huHaoController.text : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
        ageMin: _ageMinController.text.isNotEmpty ? int.tryParse(_ageMinController.text) : null,
        ageMax: _ageMaxController.text.isNotEmpty ? int.tryParse(_ageMaxController.text) : null,
        disability: _selectedDisability,
        dibao: _selectedDibao,
        isDead: _selectedIsDead,
      );
      
      
      await SearchHistoryService.saveSearch({
        'name': _nameController.text,
        'idCard': _idCardController.text,
        'huHao': _huHaoController.text,
        'address': _addressController.text,
        'ageMin': _ageMinController.text,
        'ageMax': _ageMaxController.text,
        'disability': _selectedDisability,
        'dibao': _selectedDibao,
        'isDead': _selectedIsDead,
      });
      
      if (mounted) {
        Navigator.pop(context, results);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高级搜索'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            tooltip: '保存筛选',
            onPressed: _showSaveFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: '我的筛选',
            onPressed: _savedFilters.isNotEmpty ? _showSavedFiltersMenu : null,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: '清空条件',
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            if (_showHistory && _searchHistory.isNotEmpty)
              _buildSearchHistory(),
            if (_showHistory && _searchHistory.isNotEmpty)
              const SizedBox(height: 16),
            
            
            _buildBasicInfo(),
            const SizedBox(height: 16),
            
            
            _buildAddressInfo(),
            const SizedBox(height: 16),
            
            
            _buildPersonalStatus(),
            const SizedBox(height: 24),
            
            
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _performSearch,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? '搜索中...' : '开始搜索'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchHistory() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '搜索历史',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await SearchHistoryService.clearHistory();
                    _loadSearchHistory();
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_searchHistory.length, (index) {
              final historyItem = _searchHistory[index];
              final params = historyItem['params'] as Map<String, dynamic>;
              final timestamp = DateTime.parse(historyItem['timestamp']);
              final timeStr = '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
              
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: const Icon(Icons.history, size: 20),
                title: Text(
                  SearchHistoryService.formatSearchParams(params),
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  timeStr,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () async {
                    await SearchHistoryService.deleteHistoryItem(index);
                    _loadSearchHistory();
                  },
                ),
                onTap: () => _fillFromHistory(historyItem),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                hintText: '支持模糊匹配',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idCardController,
              decoration: const InputDecoration(
                labelText: '身份证号',
                hintText: '支持后6位查询',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _huHaoController,
              decoration: const InputDecoration(
                labelText: '户号',
                hintText: '精确匹配',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddressInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地址信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '地址',
                hintText: '支持模糊匹配',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPersonalStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '个人状态',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageMinController,
                    decoration: const InputDecoration(
                      labelText: '最小年龄',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: _ageMaxController,
                    decoration: const InputDecoration(
                      labelText: '最大年龄',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            
            DropdownButtonFormField<String>(
              value: _selectedDisability,
              decoration: const InputDecoration(
                labelText: '残疾情况',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.accessible),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('全部')),
                DropdownMenuItem(value: '视力残疾', child: Text('视力残疾')),
                DropdownMenuItem(value: '听力残疾', child: Text('听力残疾')),
                DropdownMenuItem(value: '言语残疾', child: Text('言语残疾')),
                DropdownMenuItem(value: '肢体残疾', child: Text('肢体残疾')),
                DropdownMenuItem(value: '智力残疾', child: Text('智力残疾')),
                DropdownMenuItem(value: '精神残疾', child: Text('精神残疾')),
                DropdownMenuItem(value: '多重残疾', child: Text('多重残疾')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDisability = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            
            DropdownButtonFormField<String>(
              value: _selectedDibao,
              decoration: const InputDecoration(
                labelText: '低保类别',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.card_membership),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('全部')),
                DropdownMenuItem(value: '城市低保', child: Text('城市低保')),
                DropdownMenuItem(value: '农村低保', child: Text('农村低保')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDibao = value;
                });
              },
            ),
            const SizedBox(height: 12),
            
            
            DropdownButtonFormField<String>(
              value: _selectedIsDead,
              decoration: const InputDecoration(
                labelText: '是否去世',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_off),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('全部')),
                DropdownMenuItem(value: '否', child: Text('在世')),
                DropdownMenuItem(value: '是', child: Text('已去世')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedIsDead = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
