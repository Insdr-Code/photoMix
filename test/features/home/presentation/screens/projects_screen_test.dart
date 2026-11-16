import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/features/editor/application/editor_providers.dart';
import 'package:photmix_app/features/editor/domain/editor_project.dart';
import 'package:photmix_app/features/editor/domain/image_layer.dart';
import 'package:photmix_app/features/editor/presentation/screens/editor_screen.dart';
import 'package:photmix_app/features/gallery/application/gallery_providers.dart';
import 'package:photmix_app/features/home/presentation/screens/projects_screen.dart';

import '../../../../support/editor_fakes.dart';
import '../../../../support/editor_project_fakes.dart';
import '../../../../support/gallery_fakes.dart';

void main() {
  final project = EditorProject(
    id: 'saved-project',
    name: 'Proyecto guardado',
    backgroundPath: '/private/saved-project/background.jpg',
    canvasWidth: 200,
    canvasHeight: 100,
    layers: const [
      ImageLayer(
        id: 'saved-layer',
        imagePath: '/private/saved-project/layer.png',
        width: 40,
        height: 30,
      ),
    ],
    createdAt: DateTime(2026, 11, 14),
    updatedAt: DateTime(2026, 11, 15),
  );

  testWidgets('reabre un proyecto reciente con sus capas', (tester) async {
    final repository = FakeEditorProjectRepository()
      ..projects[project.id] = project;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorProjectRepositoryProvider.overrideWithValue(repository),
          editorImageLoaderProvider.overrideWithValue(FakeEditorImageLoader()),
        ],
        child: const MaterialApp(home: ProjectsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Proyecto guardado'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('project-saved-project')));
    await tester.pumpAndSettle();

    expect(find.byType(EditorScreen), findsOneWidget);
    expect(find.byKey(const Key('composition-canvas')), findsOneWidget);
  });

  testWidgets('elimina el proyecto y sus recursos asociados', (tester) async {
    final repository = FakeEditorProjectRepository()
      ..projects[project.id] = project;
    final storage = FakeImageFileStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorProjectRepositoryProvider.overrideWithValue(repository),
          imageFileStorageProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(home: ProjectsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete-project-saved-project')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-project')));
    await tester.pumpAndSettle();

    expect(repository.projects, isEmpty);
    expect(storage.deletedProjectIds, ['saved-project']);
    expect(find.text('Aún no tienes proyectos'), findsOneWidget);
  });
}
