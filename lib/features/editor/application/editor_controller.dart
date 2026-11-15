import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../gallery/domain/gallery_models.dart';
import '../domain/editor_geometry.dart';
import '../domain/editor_project.dart';
import '../domain/image_layer.dart';
import 'editor_providers.dart';
import 'editor_state.dart';

const _keepSelection = Object();

class EditorController extends Notifier<EditorState> {
  static const _minLayerScale = 0.05;
  static const _maxLayerScale = 20.0;

  final _loadedImages = <String, Image>{};
  ImageLayer? _transformStartLayer;
  bool _disposed = false;

  @override
  EditorState build() {
    ref.onDispose(_onDispose);
    return const EditorState();
  }

  Future<void> load(PhotoSelection selection) async {
    if (state.status == EditorStatus.loading) return;

    _disposeImages();
    state = const EditorState(status: EditorStatus.loading);
    final paths = {
      selection.backgroundPath,
      ...selection.additionalImagePaths,
    }.toList(growable: false);

    final loadedImages = <String, Image>{};
    try {
      for (final path in paths) {
        final image = await ref.read(editorImageLoaderProvider).loadImage(path);
        if (_disposed) {
          for (final loadedImage in loadedImages.values) {
            loadedImage.dispose();
          }
          image.dispose();
          return;
        }
        loadedImages[path] = image;
      }

      final background = loadedImages[selection.backgroundPath]!;
      final now = DateTime.now();
      final layers = <ImageLayer>[];
      for (
        var index = 0;
        index < selection.additionalImagePaths.length;
        index++
      ) {
        final path = selection.additionalImagePaths[index];
        final image = loadedImages[path]!;
        final initialScale = math.min(
          background.width * 0.4 / image.width,
          background.height * 0.4 / image.height,
        );
        final offset = (index % 5) * 0.035;
        layers.add(
          ImageLayer(
            id: const Uuid().v4(),
            imagePath: path,
            positionX: 0.5 + offset,
            positionY: 0.5 + offset,
            width: image.width.toDouble(),
            height: image.height.toDouble(),
            scale: initialScale,
            zIndex: index,
          ),
        );
      }

      _loadedImages.addAll(loadedImages);
      state = EditorState(
        status: EditorStatus.ready,
        project: EditorProject(
          id: selection.projectId,
          name: 'Nueva composición',
          backgroundPath: selection.backgroundPath,
          canvasWidth: background.width,
          canvasHeight: background.height,
          layers: layers,
          createdAt: now,
          updatedAt: now,
        ),
        images: Map.unmodifiable(_loadedImages),
        selectedLayerId: layers.isEmpty ? null : layers.last.id,
      );
    } catch (_) {
      for (final image in loadedImages.values) {
        image.dispose();
      }
      if (!_disposed) {
        state = const EditorState(
          status: EditorStatus.failure,
          errorMessage:
              'No pudimos abrir una de las imágenes. Vuelve a seleccionarlas.',
        );
      }
    }
  }

  void selectAt(Offset normalizedPoint) {
    final project = state.project;
    if (state.status != EditorStatus.ready || project == null) return;
    final layer = EditorGeometry.topLayerAt(project, normalizedPoint);
    state = state.copyWith(selectedLayerId: layer?.id);
  }

  void selectLayer(String layerId) {
    final project = state.project;
    if (project == null) return;
    final exists = project.layers.any((layer) => layer.id == layerId);
    if (exists) state = state.copyWith(selectedLayerId: layerId);
  }

  void beginTransform(Offset normalizedPoint) {
    selectAt(normalizedPoint);
    final layer = state.selectedLayer;
    _transformStartLayer = layer == null || layer.locked || !layer.visible
        ? null
        : layer;
  }

  void updateTransform({
    required Offset normalizedDelta,
    required double scale,
    required double rotation,
  }) {
    final initialLayer = _transformStartLayer;
    if (initialLayer == null) return;

    final updatedLayer = initialLayer.copyWith(
      positionX: _clampUnit(initialLayer.positionX + normalizedDelta.dx),
      positionY: _clampUnit(initialLayer.positionY + normalizedDelta.dy),
      scale: (initialLayer.scale * scale).clamp(_minLayerScale, _maxLayerScale),
      rotation: initialLayer.rotation + rotation,
    );
    _replaceLayer(updatedLayer);
  }

  void setSelectedOpacity(double opacity) {
    final layer = state.selectedLayer;
    if (layer == null || layer.locked) return;
    _replaceLayer(layer.copyWith(opacity: _clampUnit(opacity)));
  }

  void duplicateSelected() {
    final project = state.project;
    final layer = state.selectedLayer;
    if (project == null || layer == null || layer.locked) return;

    final highestZIndex = project.layers.fold<int>(
      0,
      (highest, current) => math.max(highest, current.zIndex),
    );
    final duplicate = layer.copyWith(
      id: const Uuid().v4(),
      positionX: _clampUnit(layer.positionX + 0.035),
      positionY: _clampUnit(layer.positionY + 0.035),
      zIndex: highestZIndex + 1,
    );
    _updateProject(
      layers: [...project.layers, duplicate],
      selectedLayerId: duplicate.id,
    );
  }

  void deleteSelected() {
    final project = state.project;
    final layer = state.selectedLayer;
    if (project == null || layer == null || layer.locked) return;

    final remaining = project.layers
        .where((current) => current.id != layer.id)
        .toList(growable: false);
    remaining.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    _updateProject(
      layers: remaining,
      selectedLayerId: remaining.isEmpty ? null : remaining.last.id,
    );
  }

  void _replaceLayer(ImageLayer updatedLayer) {
    final project = state.project;
    if (project == null) return;
    final layers = project.layers
        .map((layer) => layer.id == updatedLayer.id ? updatedLayer : layer)
        .toList(growable: false);
    _updateProject(layers: layers);
  }

  void _updateProject({
    required List<ImageLayer> layers,
    Object? selectedLayerId = _keepSelection,
  }) {
    final project = state.project;
    if (project == null) return;
    final updatedProject = project.copyWith(
      layers: layers,
      updatedAt: DateTime.now(),
    );
    if (identical(selectedLayerId, _keepSelection)) {
      state = state.copyWith(project: updatedProject);
    } else {
      state = state.copyWith(
        project: updatedProject,
        selectedLayerId: selectedLayerId,
      );
    }
  }

  double _clampUnit(double value) => value.clamp(0.0, 1.0);

  void _onDispose() {
    _disposed = true;
    _disposeImages();
  }

  void _disposeImages() {
    for (final image in _loadedImages.values) {
      image.dispose();
    }
    _loadedImages.clear();
  }
}
