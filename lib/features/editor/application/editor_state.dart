import 'dart:ui' as ui;

import '../domain/editor_project.dart';
import '../domain/image_layer.dart';

enum EditorStatus { initial, loading, ready, failure }

const _unchanged = Object();

class EditorState {
  const EditorState({
    this.status = EditorStatus.initial,
    this.project,
    this.images = const {},
    this.selectedLayerId,
    this.canUndo = false,
    this.canRedo = false,
    this.errorMessage,
  });

  final EditorStatus status;
  final EditorProject? project;
  final Map<String, ui.Image> images;
  final String? selectedLayerId;
  final bool canUndo;
  final bool canRedo;
  final String? errorMessage;

  ImageLayer? get selectedLayer {
    final layers = project?.layers;
    if (layers == null) return null;
    for (final layer in layers) {
      if (layer.id == selectedLayerId) return layer;
    }
    return null;
  }

  EditorState copyWith({
    EditorStatus? status,
    Object? project = _unchanged,
    Map<String, ui.Image>? images,
    Object? selectedLayerId = _unchanged,
    bool? canUndo,
    bool? canRedo,
    Object? errorMessage = _unchanged,
  }) {
    return EditorState(
      status: status ?? this.status,
      project: identical(project, _unchanged)
          ? this.project
          : project as EditorProject?,
      images: images ?? this.images,
      selectedLayerId: identical(selectedLayerId, _unchanged)
          ? this.selectedLayerId
          : selectedLayerId as String?,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
