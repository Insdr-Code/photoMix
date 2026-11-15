import 'dart:io';
import 'dart:ui' as ui;

import '../domain/editor_image_loader.dart';

class FileEditorImageLoader implements EditorImageLoader {
  const FileEditorImageLoader();

  @override
  Future<ui.Image> loadImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }
}
