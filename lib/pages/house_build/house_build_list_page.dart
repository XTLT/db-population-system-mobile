import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../api/house_build_api.dart';
import '../../models/house_build_app.dart';
import 'house_build_edit_page.dart';

/// 宅基地建房申请列表：查询、新建、编辑、导出 Excel/PDF。
class HouseBuildListPage extends StatefulWidget {
  const HouseBuildListPage({super.key});

  @override
  State<HouseBuildListPage> createState() => _HouseBuildListPageState();
}

class _HouseBuildListPageState extends State<HouseBuildListPage> {
  final _searchController = TextEditingController();
  List<HouseBuildSummary> _items = [];
  double _sumArea = 0;
  bool _loading = false;
  String _status = '';

  static const _statusOptions = [
    ['', '全部'],
    ['draft', '草稿'],
    ['submitted', '已提交'],
    ['approved', '已审批'],
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await HouseBuildApi.list(
        keyword: _searchController.text.trim(),
        status: _status,
      );
      final raw = (result['items'] ?? []) as List<dynamic>;
      setState(() {
        _items = raw
            .map((e) => HouseBuildSummary.fromJson(e as Map<String, dynamic>))
            .toList();
        final sum = result['sum_apply_area'];
        _sumArea = sum is num ? sum.toDouble() : double.tryParse('$sum') ?? 0;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEdit(String? appId) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => HouseBuildEditPage(appId: appId)),
    );
    _load();
  }

  Future<void> _export(HouseBuildSummary item, String fmt) async {
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('正在生成文件…')));
      final path = await HouseBuildApi.download(item.id, fmt);
      await Share.shareXFiles([XFile(path)], text: '宅基地建房申请 ${item.appNo}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  void _showExportSheet(HouseBuildSummary item) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('${item.ownerName}  ${item.appNo}'),
              subtitle: const Text('导出后可直接分享到微信或打印机'),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('导出 Excel'),
              onTap: () {
                Navigator.pop(sheetContext);
                _export(item, 'xlsx');
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('导出 PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                _export(item, 'pdf');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('宅基地建房申请')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(null),
        icon: const Icon(Icons.add),
        label: const Text('新建申请'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '搜索',
                      hintText: '姓名 / 身份证 / 户号 / 编号',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _load(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _status,
                  items: _statusOptions
                      .map((e) => DropdownMenuItem(
                            value: e[0],
                            child: Text(e[1]),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _status = value ?? '');
                    _load();
                  },
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  tooltip: '刷新',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '共 ${_items.length} 条，申请面积合计 ${_fmt(_sumArea)} ㎡',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading && _items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('还没有建房申请记录')),
                          ],
                        )
                      : ListView.separated(
                          itemCount: _items.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              title: Text('${item.ownerName}  ${item.appNo}'),
                              subtitle: Text(
                                '户号 ${item.huHao}  小组 ${item.groupName}\n'
                                '申请面积 ${item.areaText} ㎡   ${item.createdAt}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Chip(
                                    label: Text(item.statusText,
                                        style: const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.ios_share),
                                    tooltip: '导出',
                                    onPressed: () => _showExportSheet(item),
                                  ),
                                ],
                              ),
                              onTap: () => _openEdit(item.id),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double value) {
    if (value <= 0) return '0';
    final text = value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return text;
  }
}
