import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/utils/pagination_mixin.dart';

void main() {
  group('LoadingStatusWidget Tests', () {
    testWidgets('should show progress indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStatusWidget(
              isLoading: true,
              hasMore: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when error', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStatusWidget(
              isLoading: false,
              hasMore: true,
              errorMessage: 'Network error',
            ),
          ),
        ),
      );

      expect(find.text('加载失败: Network error'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should call onRetry when retry button pressed', (WidgetTester tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStatusWidget(
              isLoading: false,
              hasMore: true,
              errorMessage: 'Network error',
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(retryCalled, true);
    });

    testWidgets('should show no more data message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStatusWidget(
              isLoading: false,
              hasMore: false,
            ),
          ),
        ),
      );

      expect(find.text('没有更多数据了'), findsOneWidget);
    });

    testWidgets('should show nothing when has more and not loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingStatusWidget(
              isLoading: false,
              hasMore: true,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('EmptyDataWidget Tests', () {
    testWidgets('should show default message and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDataWidget(),
          ),
        ),
      );

      expect(find.text('暂无数据'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('should show custom message and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDataWidget(
              message: '没有找到记录',
              icon: Icons.search_off,
            ),
          ),
        ),
      );

      expect(find.text('没有找到记录'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should show refresh button when callback provided', (WidgetTester tester) async {
      var refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDataWidget(
              onRefresh: () {
                refreshCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('刷新'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      expect(refreshCalled, true);
    });

    testWidgets('should not show refresh button when callback null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyDataWidget(),
          ),
        ),
      );

      expect(find.byType(TextButton), findsNothing);
    });
  });
}
