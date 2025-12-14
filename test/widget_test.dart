import 'package:flutter_test/flutter_test.dart';
import 'package:rentease_app/main.dart';
import 'package:rentease_app/services/theme_service.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    final themeService = ThemeService();
    await tester.pumpWidget(MyApp(themeService: themeService));
    await tester.pumpAndSettle();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
