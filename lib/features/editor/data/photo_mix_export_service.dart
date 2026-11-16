import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/editor_export_service.dart';
import '../domain/editor_project.dart';
import '../domain/export_format.dart';
import 'composition_renderer.dart';

class PhotoMixExportService implements EditorExportService {
  PhotoMixExportService() : _renderer = const CompositionRenderer();

  final CompositionRenderer _renderer;

  @override
  Future<File> render({
    required EditorProject project,
    required ExportFormat format,
    required int quality,
  }) async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final file = File(
      p.join(
        directory.path,
        'photmix_${project.id}_$timestamp.${format.extension}',
      ),
    );
    await _renderer.render(
      project: project,
      format: format,
      quality: quality,
      outputPath: file.path,
    );
    return file;
  }

  @override
  Future<void> saveToGallery(File file, {required String filename}) async {
    await PhotoManager.editor.saveImage(
      await file.readAsBytes(),
      filename: filename,
      title: filename,
      relativePath: 'Pictures/PhotoMix',
    );
  }

  @override
  Future<void> share(File file, {required Rect sharePositionOrigin}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}
