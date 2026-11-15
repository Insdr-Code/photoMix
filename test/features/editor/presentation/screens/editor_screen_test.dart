import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/core/theme/app_theme.dart';
import 'package:photmix_app/features/editor/application/editor_providers.dart';
import 'package:photmix_app/features/editor/presentation/screens/editor_screen.dart';
import 'package:photmix_app/features/gallery/domain/gallery_models.dart';

import '../../../../support/editor_fakes.dart';

void main() {
  const selection = PhotoSelection(
    projectId: 'project',
    backgroundPath: 'background.jpg',
    additionalImagePaths: ['layer.jpg', 'second.png'],
  );

  Future<ProviderContainer> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorImageLoaderProvider.overrideWithValue(FakeEditorImageLoader()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const EditorScreen(selection: selection),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(EditorScreen));
    return ProviderScope.containerOf(context);
  }

  testWidgets('muestra el lienzo, duplica y elimina capas', (tester) async {
    final container = await pumpEditor(tester);

    expect(find.byKey(const Key('composition-canvas')), findsOneWidget);
    expect(find.text('Capa 2'), findsWidgets);

    await tester.tap(find.byKey(const Key('duplicate-layer')));
    await tester.pump();
    expect(
      container.read(editorControllerProvider).project?.layers,
      hasLength(3),
    );
    expect(find.text('Capa 3'), findsWidgets);

    await tester.tap(find.byKey(const Key('delete-layer')));
    await tester.pump();
    expect(
      container.read(editorControllerProvider).project?.layers,
      hasLength(2),
    );
    expect(find.text('Capa 2'), findsWidgets);
  });

  testWidgets('selecciona, deselecciona y mueve capas mediante gestos', (
    tester,
  ) async {
    final container = await pumpEditor(tester);
    final canvasFinder = find.byKey(const Key('composition-canvas'));
    final canvasRect = tester.getRect(canvasFinder);

    await tester.tapAt(canvasRect.topLeft + const Offset(5, 5));
    await tester.pump();
    expect(
      find.text('Selecciona una imagen en el lienzo o en la lista de capas.'),
      findsOneWidget,
    );

    final initialLayer = container
        .read(editorControllerProvider)
        .project!
        .layers
        .last;
    final layerCenter = Offset(
      canvasRect.left + canvasRect.width * initialLayer.positionX,
      canvasRect.top + canvasRect.height * initialLayer.positionY,
    );
    await tester.tapAt(layerCenter);
    await tester.pump();
    expect(container.read(editorControllerProvider).selectedLayer, isNotNull);

    await tester.dragFrom(layerCenter, const Offset(45, 20));
    await tester.pump();

    final movedLayer = container.read(editorControllerProvider).selectedLayer!;
    expect(movedLayer.id, initialLayer.id);
    expect(movedLayer.positionX, greaterThan(initialLayer.positionX));
    expect(movedLayer.positionY, greaterThan(initialLayer.positionY));
  });

  testWidgets('actualiza opacidad desde el control', (tester) async {
    final container = await pumpEditor(tester);
    final slider = find.byKey(const Key('opacity-slider'));
    final originalOpacity = container
        .read(editorControllerProvider)
        .selectedLayer!
        .opacity;

    await tester.drag(slider, const Offset(-120, 0));
    await tester.pump();

    expect(
      container.read(editorControllerProvider).selectedLayer!.opacity,
      lessThan(originalOpacity),
    );
    expect(container.read(editorControllerProvider).canUndo, isTrue);
  });

  testWidgets('permite ocultar, bloquear, recortar y recuperar capas', (
    tester,
  ) async {
    final container = await pumpEditor(tester);
    final controller = container.read(editorControllerProvider);
    final layerId = controller.selectedLayer!.id;

    await tester.tap(find.byKey(Key('visibility-$layerId')));
    await tester.pump();
    expect(
      container
          .read(editorControllerProvider)
          .project!
          .layers
          .firstWhere((layer) => layer.id == layerId)
          .visible,
      isFalse,
    );

    await tester.tap(find.byKey(const Key('undo')));
    await tester.pump();
    expect(
      container
          .read(editorControllerProvider)
          .project!
          .layers
          .firstWhere((layer) => layer.id == layerId)
          .visible,
      isTrue,
    );

    await tester.tap(find.byKey(Key('lock-$layerId')));
    await tester.pump();
    expect(
      container
          .read(editorControllerProvider)
          .project!
          .layers
          .firstWhere((layer) => layer.id == layerId)
          .locked,
      isTrue,
    );
    await tester.tap(find.byKey(Key('lock-$layerId')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('crop-layer')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('crop-left')), const Offset(70, 0));
    await tester.pump();
    await tester.tap(find.byKey(const Key('apply-crop')));
    await tester.pumpAndSettle();

    expect(
      container
          .read(editorControllerProvider)
          .project!
          .layers
          .firstWhere((layer) => layer.id == layerId)
          .crop
          .left,
      greaterThan(0),
    );
    expect(find.byKey(const Key('redo')), findsOneWidget);
  });

  testWidgets('reordena capas usando los controles de profundidad', (
    tester,
  ) async {
    final container = await pumpEditor(tester);
    final selectedLayerId = container
        .read(editorControllerProvider)
        .selectedLayer!
        .id;

    await tester.tap(find.byKey(const Key('send-layer-back')));
    await tester.pump();

    final orderedLayers = container
        .read(editorControllerProvider)
        .project!
        .orderedLayers;
    expect(orderedLayers.first.id, selectedLayerId);
    expect(find.byKey(const Key('bring-layer-front')), findsOneWidget);
  });
}
