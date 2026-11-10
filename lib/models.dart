// параметры запроса на анализ
class AnalysisRequest {
  final String videoPath;
  final String exercise; // 'squat'
  final String view;     // 'front' или 'side'

  AnalysisRequest({
    required this.videoPath,
    required this.exercise,
    required this.view,
  });
}

// обнаруженная ошибка в конкретном повторении
class DetectedError {
  final String code;
  final String message;
  final String recommendation;

  DetectedError({
    required this.code,
    required this.message,
    required this.recommendation,
  });

  factory DetectedError.fromJson(Map<String, dynamic> json) {
    return DetectedError(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }
}

// информация о конкретном повторении
class Repetition {
  final int index;
  final double startSec;
  final double endSec;
  final String assessment;
  final List<DetectedError> detectedErrors;

  Repetition({
    required this.index,
    required this.startSec,
    required this.endSec,
    required this.assessment,
    required this.detectedErrors,
  });

  factory Repetition.fromJson(Map<String, dynamic> json) {
    var rawErrors = json['detected_errors'] as List? ?? [];
    List<DetectedError> errors = rawErrors
        .map((e) => DetectedError.fromJson(e as Map<String, dynamic>))
        .toList();

    return Repetition(
      index: json['index'] ?? 0,
      startSec: (json['start_sec'] as num?)?.toDouble() ?? 0.0,
      endSec: (json['end_sec'] as num?)?.toDouble() ?? 0.0,
      assessment: json['assessment'] ?? 'not_assessable',
      detectedErrors: errors,
    );
  }
}

// полный результат анализа
class AnalysisResult {
  final String schemaVersion;
  final String exercise;
  final String view;
  final String modelVersion;
  final String assessment; // completed, partial, not_assessable
  final String? reasonCode;
  final List<Repetition> repetitions;

  AnalysisResult({
    required this.schemaVersion,
    required this.exercise,
    required this.view,
    required this.modelVersion,
    required this.assessment,
    this.reasonCode,
    required this.repetitions,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    var rawReps = json['repetitions'] as List? ?? [];
    List<Repetition> reps = rawReps
        .map((r) => Repetition.fromJson(r as Map<String, dynamic>))
        .toList();

    return AnalysisResult(
      schemaVersion: json['schema_version'] ?? '1.0',
      exercise: json['exercise'] ?? 'squat',
      view: json['view'] ?? 'front',
      modelVersion: json['model_version'] ?? 'mock-version-1.0',
      assessment: json['assessment'] ?? 'not_assessable',
      reasonCode: json['reason_code'],
      repetitions: reps,
    );
  }
}