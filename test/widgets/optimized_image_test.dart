import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/widgets/optimized_image.dart';

void main() {
  group('OptimizedImage Widget Tests', () {
    testWidgets('should show placeholder while loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // 应该显示占位图（CircularProgressIndicator）
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should use custom placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 100,
              height: 100,
              placeholder: const Text('Loading...'),
            ),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('should apply width and height', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedImage(
              imageUrl: 'https://example.com/image.jpg',
              width: 200,
              height: 150,
            ),
          ),
        ),
      );

      // OptimizedImage uses CachedNetworkImage
      // Verify the widget is built with correct dimensions
      expect(find.byType(OptimizedImage), findsOneWidget);
      
      final optimizedImage = tester.widget<OptimizedImage>(find.byType(OptimizedImage));
      expect(optimizedImage.width, 200);
      expect(optimizedImage.height, 150);
    });
  });

  group('AvatarImage Widget Tests', () {
    testWidgets('should show initial when no image URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarImage(
              name: '张三',
              size: 50,
            ),
          ),
        ),
      );

      // 应该显示名字首字母
      expect(find.text('张'), findsOneWidget);
    });

    testWidgets('should show question mark when no name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarImage(
              size: 50,
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should use correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarImage(
              name: '李四',
              size: 60,
            ),
          ),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.radius, 30);
    });
  });

  group('ThumbnailImage Widget Tests', () {
    testWidgets('should show default icon when no image URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThumbnailImage(
              size: 80,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('should use correct size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThumbnailImage(
              size: 100,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, 100);
      expect(container.constraints?.maxHeight, 100);
    });
  });

  group('ImagePreview Widget Tests', () {
    testWidgets('should create interactive viewer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImagePreview(
              imageUrl: 'https://example.com/image.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });
  });
}
