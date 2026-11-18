import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/gallery_models.dart';
import 'gallery_providers.dart';
import 'gallery_state.dart';

class GalleryController extends Notifier<GalleryState> {
  static const _pageSize = 80;

  @override
  GalleryState build() => const GalleryState();

  Future<void> load() async {
    if (state.status == GalleryStatus.loading || state.isBusy) return;

    state = state.copyWith(status: GalleryStatus.loading, errorMessage: null);

    try {
      final repository = ref.read(galleryRepositoryProvider);
      final hasAccess = await repository.requestAccess();
      if (!hasAccess) {
        state = state.copyWith(status: GalleryStatus.permissionDenied);
        return;
      }

      final albums = await repository.getAlbums();
      if (albums.isEmpty) {
        state = state.copyWith(
          status: GalleryStatus.ready,
          albums: const [],
          selectedAlbumId: null,
          images: const [],
          currentPage: 0,
          hasMore: false,
        );
        return;
      }

      final album = albums.first;
      final images = await repository.getImages(
        albumId: album.id,
        page: 1,
        pageSize: _pageSize,
      );
      state = state.copyWith(
        status: GalleryStatus.ready,
        albums: albums,
        selectedAlbumId: album.id,
        images: images,
        currentPage: 1,
        hasMore: images.length == _pageSize && images.length < album.imageCount,
      );
    } catch (_) {
      state = state.copyWith(
        status: GalleryStatus.failure,
        errorMessage: 'No pudimos consultar tu galería. Inténtalo de nuevo.',
      );
    }
  }

  Future<void> openSettings() {
    return ref.read(galleryRepositoryProvider).openSettings();
  }

  Future<void> selectAlbum(GalleryAlbum album) async {
    if (state.isBusy || state.selectedAlbumId == album.id) return;

    state = state.copyWith(
      status: GalleryStatus.loading,
      selectedAlbumId: album.id,
      images: const [],
      currentPage: 0,
      hasMore: false,
      errorMessage: null,
    );

    try {
      final images = await ref
          .read(galleryRepositoryProvider)
          .getImages(albumId: album.id, page: 1, pageSize: _pageSize);
      state = state.copyWith(
        status: GalleryStatus.ready,
        images: images,
        currentPage: 1,
        hasMore: images.length == _pageSize && images.length < album.imageCount,
      );
    } catch (_) {
      state = state.copyWith(
        status: GalleryStatus.failure,
        errorMessage: 'No pudimos abrir este álbum.',
      );
    }
  }

  Future<void> loadMore() async {
    final albumId = state.selectedAlbumId;
    if (state.status != GalleryStatus.ready ||
        albumId == null ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);
    try {
      final nextPage = state.currentPage + 1;
      final images = await ref
          .read(galleryRepositoryProvider)
          .getImages(albumId: albumId, page: nextPage, pageSize: _pageSize);
      final allImages = [...state.images, ...images];
      final album = state.selectedAlbum;
      state = state.copyWith(
        images: allImages,
        currentPage: images.isEmpty ? state.currentPage : nextPage,
        hasMore:
            images.length == _pageSize &&
            allImages.length < (album?.imageCount ?? allImages.length),
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'No pudimos cargar más fotografías.',
      );
    }
  }

  void selectImage(GalleryImage image) {
    if (state.isBusy) return;

    final background = state.background;
    if (background == null) {
      state = state.copyWith(background: image, errorMessage: null);
      return;
    }
    if (background.id == image.id) return;

    final isSelected = state.additionalImages.any(
      (selected) => selected.id == image.id,
    );
    final additionalImages = isSelected
        ? state.additionalImages
              .where((selected) => selected.id != image.id)
              .toList(growable: false)
        : [...state.additionalImages, image];
    state = state.copyWith(additionalImages: additionalImages);
  }

  void changeBackground() {
    if (state.isBusy) return;
    state = state.copyWith(
      background: null,
      additionalImages: const [],
      errorMessage: null,
    );
  }

  Future<void> importFiles() async {
    if (state.isBusy) return;

    state = state.copyWith(isImporting: true, errorMessage: null);
    try {
      final files = await ref.read(imageFilePickerProvider).pickImages();
      final knownPaths = state.importedFilePaths.toSet();
      final newPaths = files
          .map((file) => file.path)
          .where(knownPaths.add)
          .toList(growable: false);
      state = state.copyWith(
        importedFilePaths: [...state.importedFilePaths, ...newPaths],
        isImporting: false,
      );
    } catch (_) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: 'No pudimos importar los archivos seleccionados.',
      );
    }
  }

  void clearImportedFiles() {
    if (state.isBusy) return;
    final importedPaths = state.importedFilePaths.toSet();
    state = state.copyWith(
      importedFilePaths: const [],
      background:
          state.background != null &&
              importedPaths.contains(state.background!.id)
          ? null
          : state.background,
      additionalImages: state.additionalImages
          .where((image) => !importedPaths.contains(image.id))
          .toList(growable: false),
    );
  }

  Future<PhotoSelection?> createSelection() async {
    final background = state.background;
    if (background == null || !state.canContinue) return null;

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final repository = ref.read(galleryRepositoryProvider);
      final selectedAssets = [background, ...state.additionalImages];
      final assetFiles = await Future.wait(
        selectedAssets.map((image) {
          if (state.importedFilePaths.contains(image.id)) {
            return Future<File?>.value(File(image.id));
          }
          return repository.getImageFile(image);
        }),
      );
      if (assetFiles.any((file) => file == null)) {
        throw StateError('Una imagen seleccionada no está disponible.');
      }

      final images = <File>[...assetFiles.whereType<File>()];
      final projectId = const Uuid().v4();
      final storedPaths = await ref
          .read(imageFileStorageProvider)
          .storeImages(projectId: projectId, images: images);
      if (storedPaths.isEmpty) {
        throw StateError('No se almacenó ninguna imagen.');
      }

      return PhotoSelection(
        projectId: projectId,
        backgroundPath: storedPaths.first,
        additionalImagePaths: storedPaths.skip(1).toList(growable: false),
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'No pudimos preparar las imágenes. Inténtalo de nuevo.',
      );
      return null;
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
