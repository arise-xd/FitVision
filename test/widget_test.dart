import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitvision/main.dart';

void main() {
  testWidgets('Главный экран показывает выбор видео и ракурс спереди', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitVisionApp());

    expect(find.text('FitVision'), findsOneWidget);
    expect(find.text('Выбрать видео'), findsOneWidget);
    expect(find.text('Проверить технику'), findsOneWidget);
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'front',
    );
  });

  testWidgets('Ракурс можно переключить на боковой и обратно', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitVisionApp());

    for (final view in {'Сбоку': 'side', 'Спереди': 'front'}.entries) {
      await tester.tap(find.text(view.key));
      await tester.pump();

      expect(
        tester
            .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
            .groupValue,
        view.value,
      );
    }
  });

  testWidgets('Без видео анализ не запускается и появляется подсказка', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FitVisionApp());

    await tester.tap(find.text('Проверить технику'));
    await tester.pumpAndSettle();

    expect(find.text('Пожалуйста, выберите видео файл'), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WaitingScreen), findsNothing);
  });
}
