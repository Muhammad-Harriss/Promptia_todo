
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_todo/main.dart';
import 'package:supabase_todo/routes/routes_name.dart';

void main() {
  testWidgets('Login screen loads first', (WidgetTester tester) async {
    // Build our app with login as initial route
    await tester.pumpWidget(MyApp(initialRoute: RoutesName.login));

    // ✅ Verify that login screen fields appear
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Navigate to Signup screen', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(initialRoute: RoutesName.login));

    // ✅ Tap on "SignUp" link
    await tester.tap(find.text('SignUp'));
    await tester.pumpAndSettle();

    // ✅ Verify that Signup screen fields appear
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('SignUp'), findsOneWidget);
  });
}
