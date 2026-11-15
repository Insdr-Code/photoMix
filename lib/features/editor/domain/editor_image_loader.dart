import 'dart:ui' as ui;

abstract interface class EditorImageLoader {
  Future<ui.Image> loadImage(String path);
}
