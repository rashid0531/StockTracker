import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stocktracker_frontend_dart/main.dart';
import 'package:stocktracker_frontend_dart/data/services/api_service.dart';
import 'package:stocktracker_frontend_dart/ui/core/theme.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider(create: (_) => ApiService()),
        ],
        child: const WealthTrackerApp(),
      ),
    );

    // Verify that we render the login page header immediately on launch
    await tester.pumpAndSettle();
    expect(find.text('WealthTracker'), findsOneWidget);
  });
}
