import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tflite_background_removal_service.dart';
import '../data/tflite_person_segmentation_model.dart';
import '../data/sqflite_editor_project_repository.dart';
import '../data/file_editor_image_loader.dart';
import '../data/photo_mix_export_service.dart';
import '../domain/background_removal_service.dart';
import '../domain/editor_export_service.dart';
import '../domain/editor_image_loader.dart';
import '../domain/editor_project.dart';
import '../domain/editor_project_repository.dart';
import 'editor_controller.dart';
import 'editor_state.dart';

final editorImageLoaderProvider = Provider.autoDispose<EditorImageLoader>(
  (ref) => const FileEditorImageLoader(),
);

final editorExportServiceProvider = Provider<EditorExportService>(
  (ref) => PhotoMixExportService(),
);

final backgroundRemovalServiceProvider = Provider<BackgroundRemovalService>((
  ref,
) {
  final model = TflitePersonSegmentationModel();
  final service = TfliteBackgroundRemovalService(model);
  ref.onDispose(() => model.dispose());
  return service;
});

final editorProjectRepositoryProvider = Provider<EditorProjectRepository>(
  (ref) => SqfliteEditorProjectRepository(),
);

final editorProjectsProvider = FutureProvider.autoDispose<List<EditorProject>>((
  ref,
) {
  return ref.watch(editorProjectRepositoryProvider).getRecent(limit: 100);
});

final editorControllerProvider =
    NotifierProvider.autoDispose<EditorController, EditorState>(
      EditorController.new,
    );
