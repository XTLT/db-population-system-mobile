# 测试指南

## 测试类型

### 1. 单元测试
测试独立的类、方法和函数。

**位置**: `test/` 目录

**运行命令**:
```bash
flutter test test/
```

**已实现的单元测试**:
- ✅ `utils/validators_test.dart` - 数据验证测试
- ✅ `services/network_cache_test.dart` - 网络缓存测试
- ✅ `utils/pagination_helper_test.dart` - 分页帮助类测试
- ✅ `models/person_test.dart` - 人员模型测试
- ✅ `models/student_test.dart` - 学生模型测试

### 2. Widget 测试
测试 UI 组件的行为和外观。

**位置**: `test/` 目录

**运行命令**:
```bash
flutter test test/widgets/
```

**已实现的 Widget 测试**:
- ✅ `widgets/optimized_image_test.dart` - 图片组件测试
- ✅ `widgets/pagination_widgets_test.dart` - 分页组件测试

### 3. 集成测试
测试完整的应用流程和用户交互。

**位置**: `integration_test/` 目录

**运行命令**:
```bash
flutter test integration_test/app_test.dart
```

**已实现的集成测试**:
- ✅ `app_test.dart` - 应用流程测试

## 测试覆盖率

### 核心功能测试覆盖

#### 数据层
- ✅ Person 模型
- ✅ Student 模型
- ⏳ User 模型

#### 业务逻辑层
- ✅ Validators 工具类
- ✅ NetworkCache 服务
- ✅ PaginationHelper 工具类
- ⏳ PhotoService 服务
- ⏳ OfflineDataService 服务

#### UI 层
- ✅ OptimizedImage 组件
- ✅ AvatarImage 组件
- ✅ ThumbnailImage 组件
- ✅ LoadingStatusWidget 组件
- ✅ EmptyDataWidget 组件
- ⏳ LoginPage 页面
- ⏳ HomePage 页面
- ⏳ PersonListPage 页面

## 运行所有测试

```bash
# 运行所有单元测试和 Widget 测试
flutter test

# 运行特定测试文件
flutter test test/utils/validators_test.dart

# 运行测试并生成覆盖率报告
flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 测试最佳实践

### 1. 单元测试命名规范
```dart
group('功能模块名 Tests', () {
  test('should return expected result when condition', () {
    // 测试代码
  });
});
```

### 2. Widget 测试规范
```dart
testWidgets('should show widget when condition', (WidgetTester tester) async {
  // 准备
  await tester.pumpWidget(MaterialApp(home: MyWidget()));
  
  // 执行
  await tester.tap(find.byType(Button));
  await tester.pumpAndSettle();
  
  // 验证
  expect(find.text('Expected'), findsOneWidget);
});
```

### 3. 集成测试规范
- 测试完整的用户流程
- 使用真实的用户操作
- 验证端到端的结果

## 测试数据准备

### 使用 Mock 数据
```dart
// SharedPreferences Mock
SharedPreferences.setMockInitialValues({
  'key': 'value',
});

// API Mock (需要添加依赖)
// 使用 mockito 或 http_mock_adapter
```

## 测试检查清单

### 功能测试
- [ ] 登录功能正常
- [ ] 人员查询功能正常
- [ ] 人员详情显示正确
- [ ] 人员编辑功能正常
- [ ] 学生管理功能正常
- [ ] 照片上传功能正常
- [ ] 数据统计显示正确
- [ ] 设置功能正常

### 性能测试
- [ ] 网络请求缓存有效
- [ ] 分页加载正常
- [ ] 图片加载优化有效
- [ ] 离线缓存正常

### 错误处理测试
- [ ] 网络错误处理正确
- [ ] 数据验证正确
- [ ] 错误提示友好
- [ ] 异常情况处理

### 用户体验测试
- [ ] 加载状态显示
- [ ] 空数据提示清晰
- [ ] 操作反馈及时
- [ ] 导航流程顺畅

## 测试环境配置

### 测试依赖
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### CI/CD 集成
```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
      - run: flutter test integration_test
```

## 测试报告

运行测试后，查看以下文件：
- `coverage/lcov.info` - 覆盖率数据
- `test-results/` - 测试结果（如果配置）

## 常见问题

### 1. SharedPreferences 错误
确保在测试前初始化：
```dart
SharedPreferences.setMockInitialValues({});
```

### 2. Widget 测试超时
增加超时时间：
```dart
test('test name', () async {
  // 测试代码
}, timeout: Timeout(Duration(seconds: 30)));
```

### 3. 异步测试问题
确保使用 `async/await` 和 `pumpAndSettle`：
```dart
await tester.pumpAndSettle();
```

## 测试命令速查

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/path/to/test.dart

# 运行集成测试
flutter test integration_test/app_test.dart

# 生成覆盖率
flutter test --coverage

# 在特定设备运行
flutter test -d <device_id>

# 更新 golden 文件
flutter test --update-goldens
```
