import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ringtalk/main.dart';

void main() {
  testWidgets('RingTalkApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RingTalkApp()),
    );
    // 앱이 에러 없이 렌더링되는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
