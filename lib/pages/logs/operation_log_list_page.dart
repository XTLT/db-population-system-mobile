import 'package:flutter/material.dart';
import '../../api/operation_log_api.dart';
import '../../models/operation_log.dart';

/// 操作日志列表页：展示系统操作记录。
///
/// 由设置页 `Navigator.push` 打开，构造器可 const、无必填参数。
/// 数据来自 [OperationLogApi.getOperationLogs]，含加载中 / 空态 /
/// 错误重试、下拉刷新与 AppBar 刷新按钮。
class OperationLogListPage extends StatefulWidget {
  const OperationLogListPage({super.key});

  @override
  State<OperationLogListPage> createState() => _OperationLogListPageState();
}

class _OperationLogListPageState extends State<OperationLogListPage> {
  static const int _limit = 100;

  List<OperationLog> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final logs = await OperationLogApi.getOperationLogs(limit: _limit);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final logs = await OperationLogApi.getOperationLogs(limit: _limit);
      if (!mounted) return;
      setState(() => _logs = logs);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('操作日志'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无操作日志'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _logs.length,
        itemBuilder: (context, index) => _buildLogTile(_logs[index]),
      ),
    );
  }

  Widget _buildLogTile(OperationLog log) {
    final highRisk = log.isHighRiskOperation;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: highRisk ? Colors.red.shade100 : Colors.blue.shade100,
          child: Icon(
            highRisk ? Icons.warning : Icons.person,
            color: highRisk ? Colors.red : Colors.blue,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                log.username.isEmpty ? '系统' : log.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (highRisk)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('高风险',
                    style: TextStyle(fontSize: 10, color: Colors.red)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(log.displayText,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(log.createdAt,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(width: 12),
                if (log.ipAddress.isNotEmpty) ...[
                  Icon(Icons.link, size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(log.ipAddress,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
