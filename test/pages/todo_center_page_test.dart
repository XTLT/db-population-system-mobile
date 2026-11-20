import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/pages/todo/offline_queue_page.dart';
import 'package:population_mobile/pages/todo/todo_center_page.dart';
import 'package:population_mobile/providers/sync_provider.dart';
import 'package:population_mobile/services/offline_data_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('待办工作台渲染四类卡片（接口失败时降级不崩）', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SyncProvider(),
        child: const MaterialApp(
          home: Scaffold(body: TodoCenterPage()),
        ),
      ),
    );

    // initState 里的三类接口在测试环境都会失败，等待其降级到错误态
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('村级待办'), findsOneWidget);
    expect(find.text('数据体检'), findsOneWidget);
    expect(find.text('待核销'), findsOneWidget);
    expect(find.text('到龄提醒'), findsOneWidget);
    expect(find.text('待同步数据'), findsOneWidget);
  });

  testWidgets('离线队列为空时显示空态', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OfflineQueuePage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('没有待同步的数据'), findsOneWidget);
  });

  testWidgets('离线队列有草稿时显示汇总与条目', (tester) async {
    await OfflineDataService().savePersonOffline(
      <String, dynamic>{'id_card': '520325199001011234', 'name': '张三'},
      isCreate: true,
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SyncProvider(),
        child: const MaterialApp(home: OfflineQueuePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 汇总条标签 + 条目状态文字都可能出现"待同步"
    expect(find.text('待同步'), findsWidgets);
    expect(find.text('1'), findsWidgets);
    expect(find.textContaining('张三'), findsOneWidget);
  });
}
