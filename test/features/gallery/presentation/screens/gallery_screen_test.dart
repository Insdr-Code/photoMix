import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/core/navigation/app_router.dart';
import 'package:photmix_app/core/navigation/app_routes.dart';

import 'package:photmix_app/core/theme/app_theme.dart';
import 'package:photmix_app/features/gallery/application/gallery_providers.dart';

import '../../../../support/gallery_fakes.dart';

void main() {
  testWidgets('muestra álbumes y permite elegir fondo y capas', (tester) async {
    final repository = FakeGalleryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryRepositoryProvider.overrideWithValue(repository),
          imageFileStorageProvider.overrideWithValue(FakeImageFileStorage()),
          imageFilePickerProvider.overrideWithValue(FakeImageFilePicker()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          initialRoute: AppRoutes.gallery,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Todas las fotos · 3'), findsOneWidget);
    expect(find.text('Elige un fondo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gallery-image-background')));
    await tester.pump();
    expect(find.text('FONDO'), findsOneWidget);
    expect(find.text('Añade imágenes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('gallery-image-layer')));
    await tester.pump();
    expect(find.text('Fondo seleccionado · 1 capa'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continuar'), findsOneWidget);

    await tester.tap(find.text('Todas las fotos · 3'));
    await tester.pumpAndSettle();
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
  });

  testWidgets('muestra acciones cuando el permiso está denegado', (
    tester,
  ) async {
    final repository = FakeGalleryRepository(hasAccess: false);
    final storage = FakeImageFileStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          galleryRepositoryProvider.overrideWithValue(repository),
          imageFileStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          initialRoute: AppRoutes.gallery,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acceso a tus fotos'), findsOneWidget);
    expect(find.text('Permitir acceso'), findsOneWidget);

    await tester.tap(find.text('Abrir configuración'));
    await tester.pump();
    expect(repository.openSettingsCalls, 1);
  });
}
