
import 'package:flutter/material.dart';

class PaginationHelper<T> {
  List<T> items = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentPage = 0;
  int pageSize = 20;
  String? errorMessage;
  
  final Future<List<T>> Function(int page, int pageSize) fetchData;
  
  PaginationHelper({
    required this.fetchData,
    this.pageSize = 20,
  });
  
  
  void reset() {
    currentPage = 0;
    items.clear();
    hasMore = true;
    errorMessage = null;
  }
  
  
  Future<void> load(void Function(void Function()) setState) async {
    if (isLoading || !hasMore) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final newItems = await fetchData(currentPage, pageSize);
      
      setState(() {
        isLoading = false;
        if (newItems.length < pageSize) {
          hasMore = false;
        } else {
          currentPage++;
        }
        items.addAll(newItems);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }
  
  
  Future<void> refresh(void Function(void Function()) setState) async {
    reset();
    await load(setState);
  }
  
  
  Future<void> retry(void Function(void Function()) setState) async {
    await load(setState);
  }
}


class LoadingStatusWidget extends StatelessWidget {
  final bool isLoading;
  final bool hasMore;
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  const LoadingStatusWidget({
    super.key,
    required this.isLoading,
    required this.hasMore,
    this.errorMessage,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败: $errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '没有更多数据了',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}


class EmptyDataWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRefresh;
  
  const EmptyDataWidget({
    super.key,
    this.message = '暂无数据',
    this.icon = Icons.inbox,
    this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
            ),
          ],
        ],
      ),
    );
  }
}
