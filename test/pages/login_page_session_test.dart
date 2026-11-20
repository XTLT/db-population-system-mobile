import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/pages/login/login_page.dart';

import '../test_helpers.dart';

/// 登录页"登录已过期"提示的显隐。
/// 对应 401 全局登出（AuthProvider.handleSessionExpired）后的用户可见反馈：
/// 被动登出必须给出解释，主动退出登录不能误显示。
void main() {
  ensureTestBinding();

  setUp(() {
    resetApiClientState();
    installMockAdapter((options) => jsonResponse({}));
  });

  testWidgets('被动登出（sessionExpired=true）显示过期提示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(sessionExpired: true)),
    );
    await tester.pump();

    expect(find.textContaining('登录已过期'), findsOneWidget);
    expect(find.textContaining('未保存的编辑内容'), findsOneWidget);
  });

  testWidgets('主动退出（sessionExpired=false）不显示提示', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(sessionExpired: false)),
    );
    await tester.pump();

    expect(find.textContaining('登录已过期'), findsNothing);
  });
}
