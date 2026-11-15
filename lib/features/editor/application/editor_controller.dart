import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../gallery/domain/gallery_models.dart';
import '../domain/editor_geometry.dart';
import '../domain/editor_project.dart';
import '../domain/image_layer.dart';
import '../domain/layer_crop.dart';
import 'editor_providers.dart';
import 'editor_state.dart';

const _keepSelection = Object();

class EditorController extends Notifier<EditorState> {
  static const _minLayerScale = 0.05;
  static const _maxLayerScale = 20.0;
  static const _historyLimit = 50;

  final _loadedImages = <String, Image>{};
  final _undoHistory = <_EditorSnapshot>[];
  final _redoHistory = <_EditorSnapshot>[];
  ImageLayer? _transformStartLayer;
  _EditorSnapshot? _transformStartSnapshot;
  _EditorSnapshot? _opacityStartSnapshot;
  bool _disposed = false;

  @override
  EditorState build() {
    ref.onDispose(_onDispose);
    return const EditorState();
  }

  Future<void> load(PhotoSelection selection) async {
    if (state.status == EditorStatus.loading) return;

    _disposeImages();
    _undoHistory.clear();
    _redoHistory.clear();
    _transformStartLayer = null;
    _transformStartSnapshot = null;
    _opacityStartSnapshot = null;
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
    _transformStartSnapshot = _transformStartLayer == null
        ? null
        : _currentSnapshot();
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

  void endTransform() {
    _finishContinuousEdit(_transformStartSnapshot);
    _transformStartLayer = null;
    _transformStartSnapshot = null;
  }

  void beginOpacityChange() {
    final layer = state.selectedLayer;
    _opacityStartSnapshot = layer == null || layer.locked
        ? null
        : _currentSnapshot();
  }

  void setSelectedOpacity(double opacity) {
    final layer = state.selectedLayer;
    if (layer == null || layer.locked) return;
    _replaceLayer(layer.copyWith(opacity: _clampUnit(opacity)));
  }

  void endOpacityChange() {
    _finishContinuousEdit(_opacityStartSnapshot);
    _opacityStartSnapshot = null;
  }

  void cropSelected(LayerCrop crop) {
    final layer = state.selectedLayer;
    if (layer == null || layer.locked || layer.crop == crop) return;
    _replaceLayerWithHistory(layer.copyWith(crop: crop));
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
    _commitLayers(
      layers: [...project.layers, duplicate],
      selectedLayerId: duplicate.id,
    );
  }

  void deleteSelected() {
    final layer = state.selectedLayer;
    if (layer != null) deleteLayer(layer.id);
  }

  void deleteLayer(String layerId) {
    final project = state.project;
    if (project == null) return;
    final layer = _findLayer(layerId);
    if (layer == null || layer.locked) return;

    final remaining = project.layers
        .where((current) => current.id != layerId)
        .toList(growable: false);
    remaining.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final selectedLayerId = state.selectedLayerId == layerId
        ? (remaining.isEmpty ? null : remaining.last.id)
        : state.selectedLayerId;
    _commitLayers(layers: remaining, selectedLayerId: selectedLayerId);
  }

  void toggleLayerVisibility(String layerId) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    _replaceLayerWithHistory(layer.copyWith(visible: !layer.visible));
  }

  void toggleLayerLock(String layerId) {
    final layer = _findLayer(layerId);
    if (layer == null) return;
    _replaceLayerWithHistory(layer.copyWith(locked: !layer.locked));
  }

  void reorderLayer(String layerId, int newTopIndex) {
    final project = state.project;
    final layer = _findLayer(layerId);
    if (project == null || layer == null || layer.locked) return;

    final topFirst = project.orderedLayers.reversed.toList();
    final oldTopIndex = topFirst.indexWhere((item) => item.id == layerId);
    if (newTopIndex < 0 ||
        newTopIndex >= topFirst.length ||
        oldTopIndex == newTopIndex) {
      return;
    }

    topFirst
      ..removeAt(oldTopIndex)
      ..insert(newTopIndex, layer);
    _commitDisplayOrder(topFirst);
  }

  void bringSelectedToFront() {
    final layer = state.selectedLayer;
    if (layer == null || layer.locked) return;
    _moveSelectedToTopPosition(0);
  }

  void sendSelectedToBack() {
    final layer = state.selectedLayer;
    final project = state.project;
    if (project == null || layer == null || layer.locked) return;
    _moveSelectedToTopPosition(project.layers.length - 1);
  }

  void undo() {
    final project = state.project;
    if (project == null || _undoHistory.isEmpty) return;

    final snapshot = _undoHistory.removeLast();
    _redoHistory.add(_currentSnapshot()!);
    _clearContinuousEdits();
    _restoreSnapshot(snapshot);
  }

  void redo() {
    final project = state.project;
    if (project == null || _redoHistory.isEmpty) return;

    final snapshot = _redoHistory.removeLast();
    _undoHistory.add(_currentSnapshot()!);
    _clearContinuousEdits();
    _restoreSnapshot(snapshot);
  }

  void _moveSelectedToTopPosition(int topIndex) {
    final project = state.project;
    final selected = state.selectedLayer;
    if (project == null || selected == null) return;

    final topFirst = project.orderedLayers.reversed.toList();
    final currentIndex = topFirst.indexWhere(
      (layer) => layer.id == selected.id,
    );
    if (currentIndex == topIndex) return;
    topFirst
      ..removeAt(currentIndex)
      ..insert(topIndex, selected);
    _commitDisplayOrder(topFirst);
  }

  void _commitDisplayOrder(List<ImageLayer> topFirst) {
    final ordered = topFirst.reversed.toList(growable: false);
    _commitLayers(
      layers: [
        for (var index = 0; index < ordered.length; index++)
          ordered[index].copyWith(zIndex: index),
      ],
    );
  }

  void _replaceLayerWithHistory(ImageLayer updatedLayer) {
    if (state.project == null) return;
    _pushUndo(_currentSnapshot());
    _replaceLayer(updatedLayer);
  }

  void _replaceLayer(ImageLayer updatedLayer) {
    final project = state.project;
    if (project == null) return;
    final layers = project.layers
        .map((layer) => layer.id == updatedLayer.id ? updatedLayer : layer)
        .toList(growable: false);
    _applyProject(layers: layers);
  }

  void _commitLayers({
    required List<ImageLayer> layers,
    Object? selectedLayerId = _keepSelection,
  }) {
    if (state.project == null) return;
    _pushUndo(_currentSnapshot());
    _applyProject(layers: layers, selectedLayerId: selectedLayerId);
  }

  void _applyProject({
    required List<ImageLayer> layers,
    Object? selectedLayerId = _keepSelection,
  }) {
    final project = state.project;
    if (project == null) return;
    final updatedProject = project.copyWith(
      layers: layers,
      updatedAt: DateTime.now(),
    );
    final history = _historyValues();
    if (identical(selectedLayerId, _keepSelection)) {
      state = state.copyWith(
        project: updatedProject,
        canUndo: history.$1,
        canRedo: history.$2,
      );
    } else {
      state = state.copyWith(
        project: updatedProject,
        selectedLayerId: selectedLayerId,
        canUndo: history.$1,
        canRedo: history.$2,
      );
    }
  }

  void _finishContinuousEdit(_EditorSnapshot? startSnapshot) {
    if (startSnapshot == null ||
        state.project == null ||
        identical(startSnapshot.project, state.project)) {
      return;
    }
    _pushUndo(startSnapshot);
    _publishHistory();
  }

  void _pushUndo(_EditorSnapshot? snapshot) {
    if (snapshot == null) return;
    _undoHistory.add(snapshot);
    if (_undoHistory.length > _historyLimit) _undoHistory.removeAt(0);
    _redoHistory.clear();
  }

  void _publishHistory() {
    final history = _historyValues();
    state = state.copyWith(canUndo: history.$1, canRedo: history.$2);
  }

  void _restoreSnapshot(_EditorSnapshot snapshot) {
    final selectionExists = snapshot.project.layers.any(
      (layer) => layer.id == snapshot.selectedLayerId,
    );
    final history = _historyValues();
    state = state.copyWith(
      project: snapshot.project,
      selectedLayerId: selectionExists ? snapshot.selectedLayerId : null,
      canUndo: history.$1,
      canRedo: history.$2,
    );
  }

  _EditorSnapshot? _currentSnapshot() {
    final project = state.project;
    if (project == null) return null;
    return _EditorSnapshot(project, state.selectedLayerId);
  }

  (bool, bool) _historyValues() {
    return (_undoHistory.isNotEmpty, _redoHistory.isNotEmpty);
  }

  ImageLayer? _findLayer(String layerId) {
    for (final layer in state.project?.layers ?? const <ImageLayer>[]) {
      if (layer.id == layerId) return layer;
    }
    return null;
  }

  void _clearContinuousEdits() {
    _transformStartLayer = null;
    _transformStartSnapshot = null;
    _opacityStartSnapshot = null;
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

class _EditorSnapshot {
  const _EditorSnapshot(this.project, this.selectedLayerId);

  final EditorProject project;
  final String? selectedLayerId;
}
