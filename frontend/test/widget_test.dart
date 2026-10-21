import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: "assets/.env", isOptional: true);
  });

  testWidgets('App renders LoginScreen with username and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify LoginScreen UI elements exist
    expect(find.text('Đăng Nhập'), findsWidgets);
    expect(find.text('Tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });
}
