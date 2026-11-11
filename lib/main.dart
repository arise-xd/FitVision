import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'models.dart';
import 'mock_api_service.dart';

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





      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
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

  // выбор видеофайла из памяти устройства + ДОБАВИТЬ ОГРАНИЧЕНИЕ НА ФОРМАТ ФАЙЛА
  Future<void> pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      final file = result.files.single;

      // проверка размера файла (до 100 мб)
      if (file.size > 100 * 1024 * 1024) {
        _showErrorSnackBar("Файл слишком большой! Максимальный размер 100 МБ");
        return;
      }

      setState(() {
        selectedFilePath = file.path;
        selectedFileName = file.name;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // запуск процесса анализа
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

    // отправка запроса и получение идентификатора задачи
    final analysisId = await MockApiService.submitAnalysis(request);

    setState(() {
      isUploading = false;
    });

    if (!mounted) return;

    // переход на экран ожидания
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaitingScreen(analysisId: analysisId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitVision'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // выбор ракурса съемки
            const Text('Ракурс съемки:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Спереди'),
                    value: 'front',
                    groupValue: selectedView,
                    onChanged: (val) => setState(() => selectedView = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Сбоку'),
                    value: 'side',
                    groupValue: selectedView,
                    onChanged: (val) => setState(() => selectedView = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // кнопка загрузки видео
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: isUploading ? null : pickVideo,
              icon: const Icon(Icons.upload_file),
              label: Text(selectedFileName == null ? 'Выбрать видео' : 'Изменить видео'),
            ),
            if (selectedFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Выбран файл: $selectedFileName', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),

            const Spacer(),

            // кнопка запуска анализа
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: isUploading ? null : startAnalysis,
              child: isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Проверить технику', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// экран ожидания результатов анализа
class WaitingScreen extends StatefulWidget {
  final String analysisId;
  const WaitingScreen({super.key, required this.analysisId});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  Timer? _timer;
  int _pollCount = 0;
  String _statusText = "Загрузка видео...";

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    // опрос состояния каждые 4 секунды.
    // загружаем наше видео на сервер, после загрузки наш сервер возвращает нам ссылку 
    // перенаправляем ссылку на бекенд, получаем ответ 
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      _pollCount++;

      try {
        final response = await MockApiService.checkStatus(widget.analysisId, _pollCount);
        final status = response['status'];

        setState(() {
          if (status == 'queued') _statusText = "Готовим видео к обработке...";
          if (status == 'processing') _statusText = "Анализируем вашу технику...";
        });

        if (status == 'completed') {
          _timer?.cancel(); // останавливаем опрос после получения результата
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
        setState(() {
          _statusText = "Проверяем подключение...";
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // отмена таймера при закрытии экрана
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
            Text(_statusText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('Это займет несколько секунд', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// экран результатов проверки
// после получения ответа от бекенда (т.е. генерации советов от ML-модели)
// выводим советы на экран пользователю
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
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Не удалось оценить видео. Попробуйте записать под другим углом или при лучшем освещении',
                          style: const TextStyle(fontSize: 15, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Упражнение: ${result.exercise == "squat" ? "Приседания" : result.exercise}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('Ракурс: ${result.view == "front" ? "Спереди" : "Сбоку"}'),
              const Divider(height: 30),

              const Text('Повторения:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          Text('Повторение №${rep.index} (${rep.startSec}с – ${rep.endSec}с)',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),

                          if (rep.detectedErrors.isEmpty)
                            const Text('✅ Ошибки не обнаружены, продолжайте в том же духе!', style: TextStyle(color: Colors.green))
                          else 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: rep.detectedErrors.map((err) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('❌ ${err.message}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text('💡 Совет: ${err.recommendation}'),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
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
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Проверить другое видео'),
            ),
          ],
        ),
      ),
    );
  }
}