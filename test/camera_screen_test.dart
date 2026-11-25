import 'dart:async';
import 'dart:typed_data';

import 'package:camera_platform_interface/camera_platform_interface.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitvision/main.dart';

class FakeCamera extends CameraPlatform {
  bool denied = false;
  bool noCameras = false;
  bool? audioEnabled;
  int starts = 0;
  int stops = 0;
  int disposals = 0;
  int length = 16;
  final List<String> openedCameras = [];

  @override
  Future<List<CameraDescription>> availableCameras() async => noCameras
      ? []
      : [
          const CameraDescription(
            name: 'back',
            lensDirection: CameraLensDirection.back,
            sensorOrientation: 90,
          ),
          const CameraDescription(
            name: 'front',
            lensDirection: CameraLensDirection.front,
            sensorOrientation: 90,
          ),
        ];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription description,
    MediaSettings settings,
  ) async {
    if (denied) throw CameraException('CameraAccessDenied', 'Denied');
    audioEnabled = settings.enableAudio;
    openedCameras.add(description.name);
    return openedCameras.length;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(
        CameraInitializedEvent(
          cameraId,
          1280,
          720,
          ExposureMode.auto,
          false,
          FocusMode.auto,
          false,
        ),
      );

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => Stream.multi((_) {});

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();

  @override
  Widget buildPreview(int cameraId) =>
      const SizedBox(key: Key('camera-preview'));

  @override
  Future<void> startVideoCapturing(VideoCaptureOptions options) async {
    starts++;
  }

  @override
  Future<XFile> stopVideoRecording(int cameraId) async {
    stops++;
    return XFile.fromData(
      Uint8List(16),
      path: 'recorded.mp4',
      name: 'recorded.mp4',
      length: length,
    );
  }

  @override
  Future<void> dispose(int cameraId) async {
    disposals++;
  }
}

void main() {
  late FakeCamera camera;
  late CameraPlatform original;

  setUp(() {
    original = CameraPlatform.instance;
    CameraPlatform.instance = camera = FakeCamera();
  });

  tearDown(() {
    CameraPlatform.instance = original;
  });

  Future<void> openCamera(WidgetTester tester) async {
    await tester.pumpWidget(const FitVisionApp());
    await tester.tap(find.text('Записать видео'));
    await tester.pumpAndSettle();
  }

  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('Запись без звука возвращает выбранное видео на главный экран', (
    tester,
  ) async {
    await openCamera(tester);
    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
    expect(camera.audioEnabled, isFalse);
    await tester.tap(find.text('Начать запись'));
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Сменить камеру'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Остановить запись'));
    await tester.pumpAndSettle();
    expect(camera.stops, 1);
    await tester.tap(find.text('Использовать видео'));
    await tester.pumpAndSettle();
    expect(find.text('Выбран файл: recorded.mp4'), findsOneWidget);
    expect(find.text('Изменить видео'), findsOneWidget);
    expect(camera.disposals, 1);
    await closeApp(tester);
  });

  testWidgets('Отказ в разрешении показывает подсказку и позволяет повторить', (
    tester,
  ) async {
    camera.denied = true;
    await openCamera(tester);
    expect(find.textContaining('Нет доступа к камере.'), findsOneWidget);
    camera.denied = false;
    await tester.ensureVisible(find.text('Повторить'));
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Можно сменить камеру и перезаписать ролик', (tester) async {
    await openCamera(tester);
    await tester.tap(find.text('Сменить камеру'));
    await tester.pumpAndSettle();
    expect(camera.openedCameras, ['back', 'front']);
    await tester.tap(find.text('Начать запись'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Остановить запись'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Перезаписать'));
    await tester.tap(find.text('Перезаписать'));
    await tester.pumpAndSettle();
    expect(find.text('Начать запись'), findsOneWidget);
    expect(find.text('Использовать видео'), findsNothing);
    await closeApp(tester);
  });

  testWidgets('Сворачивание останавливает запись и освобождает камеру', (
    tester,
  ) async {
    await openCamera(tester);
    await tester.tap(find.text('Начать запись'));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.stops, 1);
    expect(camera.disposals, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Использовать видео'), findsOneWidget);
    expect(camera.openedCameras, ['back']);
    await closeApp(tester);
  });

  testWidgets('Отсутствие камеры обрабатывается без падения', (tester) async {
    camera.noCameras = true;
    await openCamera(tester);
    expect(find.text('На устройстве не найдена камера.'), findsOneWidget);
    await closeApp(tester);
  });

  testWidgets('Ролик больше 100 МБ не предлагается к анализу', (tester) async {
    camera.length = 100 * 1024 * 1024 + 1;
    await openCamera(tester);
    await tester.tap(find.text('Начать запись'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Остановить запись'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Видео больше 100 МБ.'), findsOneWidget);
    expect(find.text('Использовать видео'), findsNothing);
    await closeApp(tester);
  });
}
