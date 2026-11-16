import 'dart:io';
import 'dart:ui';

import 'editor_project.dart';
import 'export_format.dart';

abstract interface class EditorExportService {
  Future<File> render({
    required EditorProject project,
    required ExportFormat format,
    required int quality,
  });

  Future<void> saveToGallery(File file, {required String filename});

  Future<void> share(File file, {required Rect sharePositionOrigin});
}
