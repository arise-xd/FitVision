import 'dart:async';

import 'package:fitvision/app_theme.dart';
import 'package:fitvision/main.dart';
import 'package:fitvision/mock_api_service.dart';
import 'package:fitvision/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AnalysisResult resultWith(String assessment, {bool withError = false}) {
  return AnalysisResult(
    schemaVersion: '1.0',
    exercise: 'squat',
    view: 'side',
    modelVersion: 'test',
    assessment: 'partial',
    repetitions: [
      Repetition(
        index: 1,
        startSec: 0,
        endSec: 2,
        assessment: assessment,
        detectedErrors: withError
            ? [
                DetectedError(
                  code: 'demo',
                  message: 'Тестовая ошибка',
                  recommendation: 'Тестовый совет',
                ),
              ]
            : [],
      ),
    ],
  );
}

void main() {
  for (final assessment in ['not_assessable', 'partial', 'unknown']) {
    testWidgets('Нет похвалы для повторения со статусом $assessment', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FitVisionTheme.dark,
          home: ResultScreen(result: resultWith(assessment)),
        ),
      );
      expect(find.textContaining('Ошибки не обнаружены'), findsNothing);
      expect(
        find.textContaining(
          assessment == 'not_assessable'
              ? 'Не удалось оценить это повторение'
              : 'Повторение оценено не полностью',
        ),
        findsOneWidget,
      );
    });
  }

  testWidgets('Похвала только для полностью оценённого повторения без ошибок', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ResultScreen(result: resultWith('completed'))),
    );
    expect(find.textContaining('Ошибки не обнаружены'), findsOneWidget);
  });

  testWidgets('Частичная оценка сохраняет обнаруженные ошибки и советы', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ResultScreen(result: resultWith('partial', withError: true)),
      ),
    );
    expect(find.textContaining('Ошибки не обнаружены'), findsNothing);
    expect(find.textContaining('Тестовая ошибка'), findsOneWidget);
    expect(find.textContaining('Тестовый совет'), findsOneWidget);
  });

  for (final fails in [false, true]) {
    testWidgets(
      'Закрытие ожидания во время запроса: ${fails ? 'ошибка' : 'успех'}',
      (tester) async {
        final response = Completer<Map<String, dynamic>>();
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WaitingScreen(
                          analysisId: 'pending',
                          loadStatus: (_, _) {
                            calls++;
                            return response.future;
                          },
                        ),
                      ),
                    ),
                    child: const Text('Открыть ожидание'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.tap(find.text('Открыть ожидание'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 4));
        expect(calls, 1);
        // Another timer tick must not start an overlapping request.
        await tester.pump(const Duration(seconds: 4));
        expect(calls, 1);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(WaitingScreen), findsNothing);
        if (fails) {
          response.completeError(StateError('Connection failed'));
        } else {
          response.complete({
            'status': 'completed',
            'result': {'assessment': 'not_assessable', 'repetitions': []},
          });
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Открыть ожидание'), findsOneWidget);
        expect(find.byType(ResultScreen), findsNothing);
      },
    );
  }

  testWidgets('Открытый экран ожидания переходит к результатам', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WaitingScreen(
          analysisId: 'completed',
          loadStatus: (_, _) async => {
            'status': 'completed',
            'result': {'assessment': 'not_assessable', 'repetitions': []},
          },
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  test(
    'Моки сохраняют выбранные ракурсы и сценарии независимых запросов',
    () async {
      final submissions = <Future<String>>[];
      for (final scenario in MockScenario.values) {
        MockApiService.currentScenario = scenario;
        for (final view in ['front', 'side']) {
          submissions.add(
            MockApiService.submitAnalysis(
              AnalysisRequest(
                videoPath: '/demo-$view.mp4',
                exercise: 'squat',
                view: view,
              ),
            ),
          );
        }
      }
      MockApiService.currentScenario = MockScenario.noErrors;
      final ids = await Future.wait(submissions);
      expect(ids.toSet().length, ids.length);
      final responses = await Future.wait(
        ids.map((id) => MockApiService.checkStatus(id, 3)),
      );
      for (var index = 0; index < responses.length; index++) {
        final result = responses[index]['result'] as Map<String, dynamic>;
        expect(result['view'], index.isEven ? 'front' : 'side');
        expect(result['exercise'], 'squat');
        if (index >= 4) {
          expect(result['assessment'], 'not_assessable');
        } else {
          expect(result['assessment'], 'completed');
          final repetitions = result['repetitions'] as List;
          expect(
            (repetitions.single['detected_errors'] as List).isEmpty,
            index < 2,
          );
        }
      }
    },
  );
}
