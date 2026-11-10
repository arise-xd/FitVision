import 'dart:async';
import 'models.dart';

enum MockScenario {
  noErrors,     // успех без ошибок
  demoError,    // найдена тестовая ошибка
  notAssessable // оценка невозможна
}

class MockApiService {
  static bool useMock = true;
  static MockScenario currentScenario = MockScenario.noErrors;

  // эмуляция отправки видео POST /api/v1/analyses
  static Future<String> submitAnalysis(AnalysisRequest request) async {
    await Future.delayed(const Duration(seconds: 1)); // имитация задержки сети
    return "mock-analysis-uuid-12345";
  }

  // эмуляция опроса статуса GET /api/v1/analyses/{analysis_id}
  static Future<Map<String, dynamic>> checkStatus(String analysisId, int pollCount) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // первые 2 запроса возвращаем статус обработки
    if (pollCount < 3) {
      return {
        "analysis_id": analysisId,
        "status": "processing",
        "result": null,
        "error": null,
      };
    }

    // возвращаем результат в зависимости от выбранного сценария
    switch (currentScenario) {
      case MockScenario.noErrors:
        return {
          "analysis_id": analysisId,
          "status": "completed",
          "result": {
            "schema_version": "1.0",
            "exercise": "squat",
            "view": "front",
            "model_version": "mock-squat-front-0.1",
            "assessment": "completed",
            "reason_code": null,
            "repetitions": [
              {
                "index": 1,
                "start_sec": 1.0,
                "end_sec": 3.5,
                "assessment": "completed",
                "reason_code": null,
                "detected_errors": []
              }
            ]
          }
        };

      case MockScenario.demoError:
        return {
          "analysis_id": analysisId,
          "status": "completed",
          "result": {
            "schema_version": "1.0",
            "exercise": "squat",
            "view": "front",
            "model_version": "mock-squat-front-0.1",
            "assessment": "completed",
            "reason_code": null,
            "repetitions": [
              {
                "index": 1,
                "start_sec": 1.2,
                "end_sec": 3.8,
                "assessment": "completed",
                "reason_code": null,
                "detected_errors": [
                  {
                    "code": "demo_error",
                    "message": "Тестовая ошибка для проверки интерфейса",
                    "recommendation": "Следите за положением коленей",
                    "confidence": null
                  }
                ]
              }
            ]
          }
        };

      case MockScenario.notAssessable:
        return {
          "analysis_id": analysisId,
          "status": "completed",
          "result": {
            "schema_version": "1.0",
            "exercise": "squat",
            "view": "front",
            "model_version": "mock-squat-front-0.1",
            "assessment": "not_assessable",
            "reason_code": "person_not_visible",
            "repetitions": []
          }
        };
    }
  }
}