import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'models.dart';
import 'mock_api_service.dart';
import 'camera_screen.dart';
import 'app_theme.dart';

void main() {
  runApp(const FitVisionApp());
}

class FitVisionApp extends StatelessWidget {
  const FitVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitVision',
      debugShowCheckedModeBanner: false,
      theme: FitVisionTheme.dark,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedView = 'front';
  String? selectedFilePath;
  String? selectedFileName;
  bool isUploading = false;
  bool isPickingFile = false; // Флаг загрузки при выборе файла

  Future<void> recordVideo() async {
    setState(() => isPickingFile = true);
    try {
      final video = await Navigator.of(context).push<RecordedVideo>(
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
      if (!mounted || video == null) return;
      setState(() {
        selectedFilePath = video.path;
        selectedFileName = video.name;
      });
    } finally {
      if (mounted) setState(() => isPickingFile = false);
    }
  }

  // Выбор видеофайла из памяти устройства с проверкой формата и размера
  Future<void> pickVideo() async {
    setState(() {
      isPickingFile = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (!mounted) return;

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final fileName = file.name.toLowerCase();

        // 1. Проверка формата (расширения)
        bool isValidExtension =
            fileName.endsWith('.mp4') ||
            fileName.endsWith('.mov') ||
            fileName.endsWith('.avi');
        if (!isValidExtension) {
          _showErrorSnackBar(
            "Неверный формат! Поддерживаются только .mp4, .mov, .avi",
          );
          return;
        }

        // 2. Проверка размера файла (до 100 МБ)
        if (file.size > 100 * 1024 * 1024) {
          _showErrorSnackBar(
            "Файл слишком большой! Максимальный размер 100 МБ",
          );
          return;
        }

        setState(() {
          selectedFilePath = file.path;
          selectedFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar("Ошибка при выборе файла");
    } finally {
      if (mounted) setState(() => isPickingFile = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ),
    );
  }

  // Запуск процесса анализа
  Future<void> startAnalysis() async {
    if (selectedFilePath == null) {
      _showErrorSnackBar("Пожалуйста, выберите видео файл");
      return;
    }

    setState(() {
      isUploading = true; // блокируем повторное нажатие кнопки
    });

    final request = AnalysisRequest(
      videoPath: selectedFilePath!,
      exercise: 'squat',
      view: selectedView,
    );

    try {
      final analysisId = await MockApiService.submitAnalysis(request);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingScreen(analysisId: analysisId),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar('Не удалось запустить анализ. Попробуйте ещё раз.');
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FitVision'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Выбор ракурса съемки
            const Text(
              'Ракурс съемки:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioGroup<String>(
              groupValue: selectedView,
              onChanged: (value) {
                if (value != null) setState(() => selectedView = value);
              },
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Спереди'),
                      value: 'front',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Сбоку'),
                      value: 'side',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: (isUploading || isPickingFile) ? null : recordVideo,
              icon: const Icon(Icons.videocam),
              label: const Text('Записать видео'),
            ),
            const SizedBox(height: 12),

            // Кнопка загрузки видео с индикатором выбора
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: (isUploading || isPickingFile) ? null : pickVideo,
              icon: isPickingFile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                isPickingFile
                    ? 'Загрузка файла...'
                    : (selectedFileName == null
                          ? 'Выбрать видео'
                          : 'Изменить видео'),
              ),
            ),
            if (selectedFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Выбран файл: $selectedFileName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: FitVisionTheme.muted,
                  ),
                ),
              ),

            const Spacer(),

            // Кнопка запуска анализа
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: FitVisionTheme.accent,
                foregroundColor: FitVisionTheme.background,
              ),
              onPressed: (isUploading || isPickingFile) ? null : startAnalysis,
              child: isUploading
                  ? const CircularProgressIndicator(
                      color: FitVisionTheme.background,
                    )
                  : const Text(
                      'Проверить технику',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Экран ожидания результатов анализа
class WaitingScreen extends StatefulWidget {
  final String analysisId;
  final Future<Map<String, dynamic>> Function(String, int) loadStatus;
  const WaitingScreen({
    super.key,
    required this.analysisId,
    this.loadStatus = MockApiService.checkStatus,
  });

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  Timer? _timer;
  int _pollCount = 0;
  bool _polling = false;
  String _statusText = "Загрузка видео...";

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (_polling || !mounted) return;
      _polling = true;
      _pollCount++;

      try {
        final response = await widget.loadStatus(widget.analysisId, _pollCount);
        if (!mounted) return;
        final status = response['status'];

        setState(() {
          if (status == 'queued') _statusText = "Готовим видео к обработке...";
          if (status == 'processing') {
            _statusText = "Анализируем вашу технику...";
          }
        });

        if (status == 'completed') {
          _timer?.cancel();
          final result = AnalysisResult.fromJson(response['result']);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(result: result),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusText = "Проверяем подключение...";
        });
      } finally {
        _polling = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Анализ выполнения')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Это займет несколько секунд',
              style: TextStyle(color: FitVisionTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// Экран результатов проверки
class ResultScreen extends StatelessWidget {
  final AnalysisResult result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Результаты')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.assessment == 'not_assessable')
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: FitVisionTheme.danger,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Не удалось оценить видео. Попробуйте записать под другим углом или при лучшем освещении',
                          style: const TextStyle(
                            fontSize: 15,
                            color: FitVisionTheme.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Упражнение: ${result.exercise == "squat" ? "Приседания" : result.exercise}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Ракурс: ${result.view == "front" ? "Спереди" : "Сбоку"}'),
              const Divider(height: 30),
              const Text(
                'Повторения:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.repetitions.length,
                itemBuilder: (context, index) {
                  final rep = result.repetitions[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Повторение №${rep.index} (${rep.startSec}с – ${rep.endSec}с)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          if (rep.assessment != 'completed')
                            Text(
                              rep.assessment == 'not_assessable'
                                  ? 'Не удалось оценить это повторение. Попробуйте записать его заново.'
                                  : 'Повторение оценено не полностью. Данных недостаточно для полного вывода.',
                              style: const TextStyle(
                                color: FitVisionTheme.muted,
                              ),
                            ),
                          if (rep.assessment == 'completed' &&
                              rep.detectedErrors.isEmpty)
                            const Text(
                              '✅ Ошибки не обнаружены, продолжайте в том же духе!',
                              style: TextStyle(color: FitVisionTheme.accent),
                            ),
                          if (rep.detectedErrors.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rep.detectedErrors.map((err) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '❌ ${err.message}',
                                        style: const TextStyle(
                                          color: FitVisionTheme.danger,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('💡 Совет: ${err.recommendation}'),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Проверить другое видео'),
            ),
          ],
        ),
      ),
    );
  }
}
