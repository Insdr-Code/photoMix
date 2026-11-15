import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/features/editor/application/editor_providers.dart';
import 'package:photmix_app/features/editor/application/editor_state.dart';
import 'package:photmix_app/features/editor/domain/layer_crop.dart';
import 'package:photmix_app/features/gallery/domain/gallery_models.dart';

import '../../../support/editor_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const selection = PhotoSelection(
    projectId: 'project',
    backgroundPath: 'background.jpg',
    additionalImagePaths: ['layer.jpg', 'second.png'],
  );

  group('EditorController', () {
    late FakeEditorImageLoader loader;
    late ProviderContainer container;
    late ProviderSubscription<EditorState> subscription;

    setUp(() {
      loader = FakeEditorImageLoader();
      container = ProviderContainer(
        overrides: [editorImageLoaderProvider.overrideWithValue(loader)],
      );
      subscription = container.listen<EditorState>(
        editorControllerProvider,
        (_, _) {},
      );
    });

    tearDown(() {
      subscription.close();
      container.dispose();
    });

    Future<EditorState> loadEditor() async {
      await container.read(editorControllerProvider.notifier).load(selection);
      return container.read(editorControllerProvider);
    }

    test('crea el lienzo original y carga todas las capas una vez', () async {
      final state = await loadEditor();

      expect(state.status, EditorStatus.ready);
      expect(state.project?.canvasWidth, 200);
      expect(state.project?.canvasHeight, 100);
      expect(state.project?.layers, hasLength(2));
      expect(state.project?.orderedLayers.map((layer) => layer.zIndex), [0, 1]);
      expect(state.selectedLayer?.imagePath, 'second.png');
      expect(loader.loadedPaths, ['background.jpg', 'layer.jpg', 'second.png']);
    });

    test('reutiliza la imagen decodificada para recursos repetidos', () async {
      const repeatedSelection = PhotoSelection(
        projectId: 'project',
        backgroundPath: 'background.jpg',
        additionalImagePaths: ['layer.jpg', 'layer.jpg'],
      );

      await container
          .read(editorControllerProvider.notifier)
          .load(repeatedSelection);

      expect(loader.loadedPaths, ['background.jpg', 'layer.jpg']);
      expect(container.read(editorControllerProvider).images, hasLength(2));
      expect(
        container.read(editorControllerProvider).project?.layers,
        hasLength(2),
      );
    });

    test('transforma usando una sola referencia inicial del gesto', () async {
      final initialState = await loadEditor();
      final controller = container.read(editorControllerProvider.notifier);
      final initialLayer = initialState.selectedLayer!;
      controller.beginTransform(
        Offset(initialLayer.positionX, initialLayer.positionY),
      );

      controller.updateTransform(
        normalizedDelta: const Offset(0.1, -0.05),
        scale: 2,
        rotation: 0.4,
      );
      controller.updateTransform(
        normalizedDelta: const Offset(0.2, 0.05),
        scale: 1.5,
        rotation: 0.2,
      );

      final transformed = container
          .read(editorControllerProvider)
          .selectedLayer!;
      expect(transformed.id, initialLayer.id);
      expect(transformed.positionX, closeTo(0.735, 0.00001));
      expect(transformed.positionY, closeTo(0.585, 0.00001));
      expect(transformed.scale, closeTo(initialLayer.scale * 1.5, 0.00001));
      expect(transformed.rotation, closeTo(0.2, 0.00001));
    });

    test('deselecciona al tocar el fondo sin capas', () async {
      await loadEditor();
      final controller = container.read(editorControllerProvider.notifier);

      controller.selectAt(const Offset(0.01, 0.01));

      expect(container.read(editorControllerProvider).selectedLayer, isNull);
    });

    test('ajusta opacidad, duplica y elimina la capa seleccionada', () async {
      await loadEditor();
      final controller = container.read(editorControllerProvider.notifier);
      final original = container.read(editorControllerProvider).selectedLayer!;

      controller.setSelectedOpacity(0.45);
      controller.duplicateSelected();

      var state = container.read(editorControllerProvider);
      expect(state.project?.layers, hasLength(3));
      expect(state.selectedLayer?.id, isNot(original.id));
      expect(state.selectedLayer?.opacity, 0.45);
      expect(state.selectedLayer?.zIndex, 2);

      controller.deleteSelected();

      state = container.read(editorControllerProvider);
      expect(state.project?.layers, hasLength(2));
      expect(state.selectedLayer?.id, original.id);
    });

    test('registra una sola operación de opacidad en el historial', () async {
      await loadEditor();
      final controller = container.read(editorControllerProvider.notifier);
      controller.beginOpacityChange();
      controller.setSelectedOpacity(0.6);
      controller.setSelectedOpacity(0.3);
      controller.endOpacityChange();

      expect(container.read(editorControllerProvider).canUndo, isTrue);
      controller.undo();
      expect(
        container.read(editorControllerProvider).selectedLayer?.opacity,
        1,
      );
      expect(container.read(editorControllerProvider).canRedo, isTrue);

      controller.redo();
      expect(
        container.read(editorControllerProvider).selectedLayer?.opacity,
        0.3,
      );
    });

    test('ordena, oculta, bloquea y recorta capas con undo y redo', () async {
      await loadEditor();
      final controller = container.read(editorControllerProvider.notifier);
      final initial = container.read(editorControllerProvider);
      final topLayer = initial.selectedLayer!;
      final bottomLayer = initial.project!.orderedLayers.first;

      controller.reorderLayer(topLayer.id, 1);
      expect(
        container.read(editorControllerProvider).project!.orderedLayers.last.id,
        bottomLayer.id,
      );

      controller.toggleLayerVisibility(topLayer.id);
      controller.toggleLayerLock(topLayer.id);
      controller.selectLayer(topLayer.id);
      controller.toggleLayerLock(topLayer.id);
      controller.cropSelected(const LayerCrop(left: 0.1, right: 0.2));

      var layer = container
          .read(editorControllerProvider)
          .project!
          .layers
          .firstWhere((item) => item.id == topLayer.id);
      expect(layer.visible, isFalse);
      expect(layer.locked, isFalse);
      expect(layer.crop.left, 0.1);
      expect(layer.crop.right, 0.2);

      controller.undo();
      layer = container
          .read(editorControllerProvider)
          .project!
          .layers
          .firstWhere((item) => item.id == topLayer.id);
      expect(layer.crop, const LayerCrop());

      controller.redo();
      expect(
        container
            .read(editorControllerProvider)
            .project!
            .layers
            .firstWhere((item) => item.id == topLayer.id)
            .crop
            .left,
        0.1,
      );
    });

    test('agrupa el movimiento en una operación de historial', () async {
      final initialState = await loadEditor();
      final controller = container.read(editorControllerProvider.notifier);
      final initialLayer = initialState.selectedLayer!;
      controller.beginTransform(
        Offset(initialLayer.positionX, initialLayer.positionY),
      );
      controller.updateTransform(
        normalizedDelta: const Offset(0.1, 0),
        scale: 1,
        rotation: 0,
      );
      controller.endTransform();

      expect(container.read(editorControllerProvider).canUndo, isTrue);
      controller.undo();
      expect(
        container.read(editorControllerProvider).selectedLayer?.positionX,
        initialLayer.positionX,
      );
    });

    test('informa fallos de decodificación', () async {
      subscription.close();
      container.dispose();
      loader = FakeEditorImageLoader(failingPath: 'second.png');
      container = ProviderContainer(
        overrides: [editorImageLoaderProvider.overrideWithValue(loader)],
      );
      subscription = container.listen<EditorState>(
        editorControllerProvider,
        (_, _) {},
      );

      await container.read(editorControllerProvider.notifier).load(selection);

      expect(
        container.read(editorControllerProvider).status,
        EditorStatus.failure,
      );
    });
  });
}
