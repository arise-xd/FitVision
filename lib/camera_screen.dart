import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

class RecordedVideo {
  const RecordedVideo({required this.path, required this.name});

  final String path;
  final String name;
}

/// Records locally on Android. Analysis still starts from the home screen.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _busy = true;
  bool _foreground = true;
  bool _recording = false;
  String? _error;
  String? _notice;
  XFile? _video;
  Timer? _timer;
  final Stopwatch _clock = Stopwatch();
  int _seconds = 0;
  // Serialize initialization, recording and lifecycle events to avoid disposing
  // a controller while a platform operation is still using it.
  Future<void> _operations = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enqueue(_openCamera);
  }

  void _enqueue(Future<void> Function() action) {
    _operations = _operations.then((_) async {
      if (!mounted) return;
      setState(() => _busy = true);
      try {
        await action();
      } on CameraException catch (e) {
        if (mounted) {
          setState(() {
            _error = e.code.startsWith('CameraAccessDenied')
                ? 'Нет доступа к камере. Разрешите его в настройках Android '
                      'для FitVision и нажмите «Повторить».'
                : 'Не удалось включить камеру или записать видео. '
                      'Попробуйте ещё раз.';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => _error = 'Не удалось сохранить видео. Попробуйте ещё раз.',
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    });
  }

  Future<void> _releaseCamera() async {
    _timer?.cancel();
    _clock.stop();
    final controller = _controller;
    _controller = null;
    _recording = false;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  Future<void> _openCamera() async {
    await _releaseCamera();
    if (!_foreground || !mounted || _video != null) return;
    if (defaultTargetPlatform != TargetPlatform.android) {
      setState(
        () => _error = 'Запись с камеры пока доступна только на Android.',
      );
      return;
    }
    setState(() => _error = null);
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
      final back = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = back < 0 ? 0 : back;
    }
    if (!mounted || !_foreground) return;
    if (_cameras.isEmpty) {
      setState(() => _error = 'На устройстве не найдена камера.');
      return;
    }
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || !_foreground) {
        await _releaseCamera();
        return;
      }
      setState(() {});
    } catch (_) {
      await _releaseCamera();
      rethrow;
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (!_foreground || controller == null || !controller.value.isInitialized) {
      return;
    }
    await controller.startVideoRecording();
    if (!mounted) return;
    _clock.reset();
    _clock.start();
    setState(() {
      _recording = true;
      _seconds = 0;
      _error = null;
      _notice = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = _clock.elapsed.inSeconds);
      if (_seconds >= 60) {
        _timer?.cancel();
        _enqueue(_stopRecording);
      }
    });
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isRecordingVideo) return;
    _timer?.cancel();
    _clock.stop();
    try {
      final video = await controller.stopVideoRecording();
      if (!mounted) return;
      _recording = false;
      if (await video.length() > 100 * 1024 * 1024) {
        if (mounted) {
          setState(
            () =>
                _error = 'Видео больше 100 МБ. Запишите более короткий ролик.',
          );
        }
        return;
      }
      if (mounted) setState(() => _video = video);
    } finally {
      _recording = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _enqueue(() async {
        if (_controller == null && _video == null) await _openCamera();
      });
    } else if (_foreground) {
      _foreground = false;
      _enqueue(() async {
        try {
          if (_recording) {
            await _stopRecording();
            if (mounted) {
              setState(
                () =>
                    _notice = 'Запись остановлена при сворачивании приложения.',
              );
            }
          }
        } finally {
          await _releaseCamera();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.stop();
    // Wait for any pending operation before disposing the camera.
    unawaited(_operations.then((_) => _releaseCamera()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    final time =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(_seconds % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: !_busy && !_recording,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _recording) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Сначала остановите запись.')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Запись упражнения')),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: FitVisionTheme.border),
                  ),
                  child: Center(
                    child: ready
                        ? CameraPreview(controller)
                        : _busy
                        ? const CircularProgressIndicator()
                        : const Icon(
                            Icons.videocam_off,
                            color: Colors.white,
                            size: 64,
                          ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _video != null
                              ? 'Видео записано · $time'
                              : '$time / 01:00',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _recording
                                    ? FitVisionTheme.danger
                                    : FitVisionTheme.accent,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Расположите телефон устойчиво: всё тело должно '
                          'попадать в кадр. Запись до 1 минуты, без звука.',
                        ),
                        if (_notice != null) Text(_notice!),
                        if (_error != null)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (_video != null) ...[
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () {
                                    final video = _video!;
                                    Navigator.of(context).pop(
                                      RecordedVideo(
                                        path: video.path,
                                        name: video.name,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.check),
                            label: const Text('Использовать видео'),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _enqueue(() async {
                                    _video = null;
                                    _notice = null;
                                    _seconds = 0;
                                    await _openCamera();
                                  }),
                            child: const Text('Перезаписать'),
                          ),
                        ] else ...[
                          FilledButton.icon(
                            onPressed: _busy || !ready
                                ? null
                                : () => _enqueue(
                                    _recording
                                        ? _stopRecording
                                        : _startRecording,
                                  ),
                            icon: Icon(
                              _recording
                                  ? Icons.stop
                                  : Icons.fiber_manual_record,
                            ),
                            label: Text(
                              _recording
                                  ? 'Остановить запись'
                                  : 'Начать запись',
                            ),
                          ),
                          if (_error != null && !ready)
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _enqueue(_openCamera),
                              child: const Text('Повторить'),
                            ),
                          if (_cameras.length > 1)
                            TextButton.icon(
                              onPressed: _busy || _recording
                                  ? null
                                  : () => _enqueue(() async {
                                      _cameraIndex =
                                          (_cameraIndex + 1) % _cameras.length;
                                      await _openCamera();
                                    }),
                              icon: const Icon(Icons.cameraswitch),
                              label: const Text('Сменить камеру'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
