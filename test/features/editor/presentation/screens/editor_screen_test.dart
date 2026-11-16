import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/core/theme/app_theme.dart';
import 'package:photmix_app/core/services/image_file_storage_provider.dart';
import 'package:photmix_app/features/editor/application/editor_providers.dart';
import 'package:photmix_app/features/editor/domain/export_format.dart';
import 'package:photmix_app/features/editor/presentation/screens/editor_screen.dart';
import 'package:photmix_app/features/gallery/domain/gallery_models.dart';

import '../../../../support/editor_export_fakes.dart';
import '../../../../support/editor_fakes.dart';
import '../../../../support/editor_project_fakes.dart';
import '../../../../support/background_removal_fakes.dart';
import '../../../../support/gallery_fakes.dart';

void main() {
  const selection = PhotoSelection(
    projectId: 'project',
    backgroundPath: 'background.jpg',
    additionalImagePaths: ['layer.jpg', 'second.png'],
  );

  Future<ProviderContainer> pumpEditor(
    WidgetTester tester, {
    FakeEditorExportService? exportService,
    FakeEditorProjectRepository? projectRepository,
    FakeBackgroundRemovalService? backgroundRemovalService,
    FakeImageFileStorage? imageFileStorage,
  }) async {
    final backgroundService =
        backgroundRemovalService ?? FakeBackgroundRemovalService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorImageLoaderProvider.overrideWithValue(FakeEditorImageLoader()),
          backgroundRemovalServiceProvider.overrideWithValue(backgroundService),
          imageFileStorageProvider.overrideWithValue(
            imageFileStorage ?? FakeImageFileStorage(),
          ),
          if (exportService != null)
            editorExportServiceProvider.overrideWithValue(exportService),
          editorProjectRepositoryProvider.overrideWithValue(
            projectRepository ?? FakeEditorProjectRepository(),
          ),
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

  testWidgets('permite eliminar el fondo de la capa seleccionada', (
    tester,
  ) async {
    final backgroundRemovalService = FakeBackgroundRemovalService();
    final imageFileStorage = FakeImageFileStorage();
    final container = await pumpEditor(
      tester,
      backgroundRemovalService: backgroundRemovalService,
      imageFileStorage: imageFileStorage,
    );
    final originalPath = container
        .read(editorControllerProvider)
        .selectedLayer!
        .imagePath;

    await tester.tap(find.byKey(const Key('remove-background')));
    await tester.pumpAndSettle();

    expect(backgroundRemovalService.sourcePaths, [originalPath]);
    expect(
      container.read(editorControllerProvider).selectedLayer?.imagePath,
      imageFileStorage.processedPaths.single,
    );
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

  testWidgets('exporta JPG con calidad configurable a la galería', (
    tester,
  ) async {
    final exportService = FakeEditorExportService();
    await pumpEditor(tester, exportService: exportService);

    await tester.tap(find.byKey(const Key('export-composition')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JPG'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('export-quality')),
      const Offset(45, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-export')));
    await tester.pumpAndSettle();

    expect(exportService.renders, hasLength(1));
    expect(exportService.renders.single.format, ExportFormat.jpg);
    expect(exportService.renders.single.quality, isNot(90));
    expect(exportService.savedFiles, hasLength(1));
    expect(exportService.savedFiles.single.filename, 'PhotoMix_project.jpg');
    expect(find.text('Composición guardada en la galería.'), findsOneWidget);
  });

  testWidgets('exporta PNG para compartir', (tester) async {
    final exportService = FakeEditorExportService();
    await pumpEditor(tester, exportService: exportService);

    await tester.tap(find.byKey(const Key('export-composition')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-export')));
    await tester.pumpAndSettle();

    expect(exportService.renders.single.format, ExportFormat.png);
    expect(exportService.sharedFiles, hasLength(1));
    expect(exportService.sharedFiles.single.origin.isEmpty, isFalse);
    expect(find.text('Abriendo opciones para compartir.'), findsOneWidget);
  });

  testWidgets('comunica los errores de exportación', (tester) async {
    final exportService = FakeEditorExportService()
      ..failure = StateError('permission denied');
    await pumpEditor(tester, exportService: exportService);

    await tester.tap(find.byKey(const Key('export-composition')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-export')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo exportar'), findsOneWidget);
  });

  testWidgets('persiste el proyecto recién creado automáticamente', (
    tester,
  ) async {
    final projectRepository = FakeEditorProjectRepository();
    await pumpEditor(tester, projectRepository: projectRepository);
    await tester.pumpAndSettle();

    expect(projectRepository.projects, contains('project'));
    expect(projectRepository.projects['project']!.layers, hasLength(2));
  });
}
