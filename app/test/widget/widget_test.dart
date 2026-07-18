import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/app.dart';

void main() {
  testWidgets('App renders the bootstrap placeholder route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BorahApp()));
    await tester.pumpAndSettle();

    expect(find.text('BORAH'), findsOneWidget);
  });
}
