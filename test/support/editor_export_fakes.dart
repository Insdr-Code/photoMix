import 'dart:io';
import 'dart:ui';

import 'package:photmix_app/features/editor/domain/editor_export_service.dart';
import 'package:photmix_app/features/editor/domain/editor_project.dart';
import 'package:photmix_app/features/editor/domain/export_format.dart';

class FakeEditorExportService implements EditorExportService {
  final renders = <({ExportFormat format, int quality, String projectId})>[];
  final savedFiles = <({String path, String filename})>[];
  final sharedFiles = <({String path, Rect origin})>[];
  Object? failure;

  @override
  Future<File> render({
    required EditorProject project,
    required ExportFormat format,
    required int quality,
  }) async {
    if (failure case final error?) throw error;
    renders.add((format: format, quality: quality, projectId: project.id));
    return File('/tmp/composition.${format.extension}');
  }

  @override
  Future<void> saveToGallery(File file, {required String filename}) async {
    if (failure case final error?) throw error;
    savedFiles.add((path: file.path, filename: filename));
  }

  @override
  Future<void> share(File file, {required Rect sharePositionOrigin}) async {
    if (failure case final error?) throw error;
    sharedFiles.add((path: file.path, origin: sharePositionOrigin));
  }
}
