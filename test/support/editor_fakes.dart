import 'dart:ui' as ui;

import 'package:photmix_app/features/editor/domain/editor_image_loader.dart';

class FakeEditorImageLoader implements EditorImageLoader {
  FakeEditorImageLoader({Map<String, ui.Size>? sizes, this.failingPath})
    : sizes =
          sizes ??
          const {
            'background.jpg': ui.Size(200, 100),
            'layer.jpg': ui.Size(40, 40),
            'second.png': ui.Size(40, 20),
          };

  final Map<String, ui.Size> sizes;
  final String? failingPath;
  final loadedPaths = <String>[];

  @override
  Future<ui.Image> loadImage(String path) async {
    loadedPaths.add(path);
    if (path == failingPath) throw StateError('Imagen inválida');
    final size = sizes[path] ?? const ui.Size(40, 40);
    return createTestImage(size.width.toInt(), size.height.toInt());
  }
}

Future<ui.Image> createTestImage(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF7057E8),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}
