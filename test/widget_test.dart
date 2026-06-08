import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smriti/main.dart';
import 'package:smriti/services/app_provider.dart';

void main() {
  testWidgets('App loads home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const SmritiApp(),
      ),
    );

    // Verify that the initial screen title is loaded
    expect(find.text('SMRITI NOTEBOOK'), findsOneWidget);
  });
}
