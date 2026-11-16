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
    this.persistenceError,
    this.isRemovingBackground = false,
    this.backgroundRemovalError,
  });

  final EditorStatus status;
  final EditorProject? project;
  final Map<String, ui.Image> images;
  final String? selectedLayerId;
  final bool canUndo;
  final bool canRedo;
  final String? errorMessage;
  final String? persistenceError;
  final bool isRemovingBackground;
  final String? backgroundRemovalError;

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
    Object? persistenceError = _unchanged,
    bool? isRemovingBackground,
    Object? backgroundRemovalError = _unchanged,
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
      persistenceError: identical(persistenceError, _unchanged)
          ? this.persistenceError
          : persistenceError as String?,
      isRemovingBackground: isRemovingBackground ?? this.isRemovingBackground,
      backgroundRemovalError: identical(backgroundRemovalError, _unchanged)
          ? this.backgroundRemovalError
          : backgroundRemovalError as String?,
    );
  }
}
