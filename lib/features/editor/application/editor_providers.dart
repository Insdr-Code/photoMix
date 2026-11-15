import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/file_editor_image_loader.dart';
import '../domain/editor_image_loader.dart';
import 'editor_controller.dart';
import 'editor_state.dart';

final editorImageLoaderProvider = Provider.autoDispose<EditorImageLoader>(
  (ref) => const FileEditorImageLoader(),
);

final editorControllerProvider =
    NotifierProvider.autoDispose<EditorController, EditorState>(
      EditorController.new,
    );
