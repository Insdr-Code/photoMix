import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/app.dart';
import 'package:photmix_app/core/theme/app_colors.dart';
import 'package:photmix_app/features/editor/application/editor_providers.dart';
import 'package:photmix_app/features/gallery/application/gallery_providers.dart';

import 'support/gallery_fakes.dart';
import 'support/editor_project_fakes.dart';

void main() {
  testWidgets('aplica el tema y muestra el inicio de PhotoMix', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryRepositoryProvider.overrideWithValue(FakeGalleryRepository()),
          editorProjectRepositoryProvider.overrideWithValue(
            FakeEditorProjectRepository(),
          ),
        ],
        child: const PhotoMixApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.theme?.colorScheme.primary, AppColors.primary);
    expect(app.theme?.scaffoldBackgroundColor, AppColors.background);
    expect(find.text('PhotoMix'), findsOneWidget);
    expect(find.text('Nueva composición'), findsOneWidget);
    expect(find.text('Proyectos recientes'), findsOneWidget);
    expect(find.text('Aún no tienes proyectos'), findsOneWidget);
  });

  testWidgets('navega del inicio al selector de fotografías', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryRepositoryProvider.overrideWithValue(FakeGalleryRepository()),
          editorProjectRepositoryProvider.overrideWithValue(
            FakeEditorProjectRepository(),
          ),
        ],
        child: const PhotoMixApp(),
      ),
    );

    await tester.tap(find.text('Nueva composición'));
    await tester.pumpAndSettle();

    expect(find.text('Elige un fondo'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Nueva composición'), findsOneWidget);
  });
}
