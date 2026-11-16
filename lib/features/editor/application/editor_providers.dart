import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sqflite_editor_project_repository.dart';
import '../data/file_editor_image_loader.dart';
import '../data/photo_mix_export_service.dart';
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
