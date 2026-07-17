import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rojgari_frontend_one/main.dart';

void main() {
  testWidgets('app opens the debug finding-service preview', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Finding Service Person'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-status-text')), findsOneWidget);
    expect(find.text('Plumber Service'), findsOneWidget);
  });
}
