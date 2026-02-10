// Базовый смоук-тест: приложение запускается с экраном выбора уровней.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yacht/ui/level_selection_screen.dart';

void main() {
  testWidgets('Экран выбора уровней отображает заголовок', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LevelSelectionScreen(),
      ),
    );
    expect(find.text('СУДОВОЙ ЖУРНАЛ'), findsOneWidget);
  });
}
