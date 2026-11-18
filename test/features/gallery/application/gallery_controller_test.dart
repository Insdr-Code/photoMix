import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:photmix_app/features/gallery/application/gallery_providers.dart';
import 'package:photmix_app/features/gallery/application/gallery_state.dart';
import 'package:photmix_app/features/gallery/domain/gallery_models.dart';
import 'package:photmix_app/features/gallery/domain/gallery_repository.dart';

import '../../../support/gallery_fakes.dart';

void main() {
  group('GalleryController', () {
    late FakeGalleryRepository repository;
    late FakeImageFileStorage storage;
    late ProviderContainer container;

    ProviderContainer createContainer({
      ImageFilePicker picker = const _EmptyImageFilePicker(),
    }) {
      return ProviderContainer(
        overrides: [
          galleryRepositoryProvider.overrideWithValue(repository),
          imageFilePickerProvider.overrideWithValue(picker),
          imageFileStorageProvider.overrideWithValue(storage),
        ],
      );
    }

    setUp(() {
      repository = FakeGalleryRepository();
      storage = FakeImageFileStorage();
      container = createContainer();
    });

    tearDown(() => container.dispose());

    test('carga álbumes y fotografías iniciales', () async {
      final controller = container.read(galleryControllerProvider.notifier);

      await controller.load();

      final state = container.read(galleryControllerProvider);
      expect(state.status, GalleryStatus.ready);
      expect(state.albums, hasLength(2));
      expect(state.selectedAlbumId, 'all');
      expect(state.images, hasLength(3));
      expect(state.hasMore, isFalse);
    });

    test('mantiene el acceso bloqueado cuando no hay permiso', () async {
      repository.hasAccess = false;
      final controller = container.read(galleryControllerProvider.notifier);

      await controller.load();

      expect(
        container.read(galleryControllerProvider).status,
        GalleryStatus.permissionDenied,
      );
      await controller.openSettings();
      expect(repository.openSettingsCalls, 1);
    });

    test('cambia de álbum y consulta sus imágenes', () async {
      final controller = container.read(galleryControllerProvider.notifier);
      await controller.load();

      await controller.selectAlbum(repository.albums[1]);

      final state = container.read(galleryControllerProvider);
      expect(state.selectedAlbumId, 'favorites');
      expect(state.images.single.id, 'layer');
    });

    test('selecciona un fondo y administra capas adicionales', () async {
      final controller = container.read(galleryControllerProvider.notifier);
      await controller.load();

      controller.selectImage(testImages[0]);
      controller.selectImage(testImages[1]);
      controller.selectImage(testImages[2]);

      var state = container.read(galleryControllerProvider);
      expect(state.background?.id, 'background');
      expect(state.additionalImages.map((image) => image.id), [
        'layer',
        'other',
      ]);

      controller.selectImage(testImages[1]);
      state = container.read(galleryControllerProvider);
      expect(state.additionalImages.single.id, 'other');

      controller.changeBackground();
      state = container.read(galleryControllerProvider);
      expect(state.background, isNull);
      expect(state.additionalImages, isEmpty);
    });

    test('carga la página siguiente', () async {
      final manyImages = List.generate(
        81,
        (index) => GalleryImage(
          id: '$index',
          name: '$index.jpg',
          width: 100,
          height: 100,
        ),
      );
      repository = FakeGalleryRepository(
        albums: const [GalleryAlbum(id: 'all', name: 'Todas', imageCount: 81)],
        imagesByAlbum: {'all': manyImages},
      );
      container.dispose();
      container = createContainer();
      final controller = container.read(galleryControllerProvider.notifier);
      await controller.load();

      expect(container.read(galleryControllerProvider).images, hasLength(80));
      expect(container.read(galleryControllerProvider).hasMore, isTrue);

      await controller.loadMore();

      final state = container.read(galleryControllerProvider);
      expect(state.images, hasLength(81));
      expect(state.currentPage, 2);
      expect(state.hasMore, isFalse);
    });

    test(
      'importa archivos y conserva el orden al crear la selección',
      () async {
        final picker = FakeImageFilePicker(
          files: [File('/imports/external.png')],
        );
        container.dispose();
        container = createContainer(picker: picker);
        final controller = container.read(galleryControllerProvider.notifier);
        await controller.load();
        controller.selectImage(testImages[0]);
        controller.selectImage(testImages[1]);

        await controller.importFiles();
        final importedImage = container
            .read(galleryControllerProvider)
            .availableImages
            .last;
        controller.selectImage(importedImage);
        final selection = await controller.createSelection();

        expect(selection, isNotNull);
        expect(selection!.backgroundPath, endsWith('000_background.jpg'));
        expect(selection.additionalImagePaths, hasLength(2));
        expect(selection.additionalImagePaths[0], endsWith('001_layer.jpg'));
        expect(selection.additionalImagePaths[1], endsWith('002_external.png'));
        expect(storage.projectId, selection.projectId);
        expect(storage.sourcePaths, [
          '/mock/background.jpg',
          '/mock/layer.jpg',
          '/imports/external.png',
        ]);
        expect(container.read(galleryControllerProvider).isSaving, isFalse);
      },
    );

    test('permite usar un archivo importado como fondo del proyecto', () async {
      final picker = FakeImageFilePicker(
        files: [File('/imports/background.png')],
      );
      container.dispose();
      container = createContainer(picker: picker);
      final controller = container.read(galleryControllerProvider.notifier);
      await controller.load();
      await controller.importFiles();
      controller.selectImage(
        container.read(galleryControllerProvider).availableImages.last,
      );

      final selection = await controller.createSelection();

      expect(selection, isNotNull);
      expect(selection!.backgroundPath, endsWith('000_background.png'));
      expect(selection.additionalImagePaths, isEmpty);
      expect(storage.sourcePaths, ['/imports/background.png']);
    });
  });
}

class _EmptyImageFilePicker implements ImageFilePicker {
  const _EmptyImageFilePicker();

  @override
  Future<List<File>> pickImages() async => const [];
}
