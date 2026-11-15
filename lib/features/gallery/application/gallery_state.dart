import '../domain/gallery_models.dart';

enum GalleryStatus { initial, loading, ready, permissionDenied, failure }

const _unchanged = Object();

class GalleryState {
  const GalleryState({
    this.status = GalleryStatus.initial,
    this.albums = const [],
    this.selectedAlbumId,
    this.images = const [],
    this.currentPage = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.background,
    this.additionalImages = const [],
    this.importedFilePaths = const [],
    this.isImporting = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final GalleryStatus status;
  final List<GalleryAlbum> albums;
  final String? selectedAlbumId;
  final List<GalleryImage> images;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final GalleryImage? background;
  final List<GalleryImage> additionalImages;
  final List<String> importedFilePaths;
  final bool isImporting;
  final bool isSaving;
  final String? errorMessage;

  GalleryAlbum? get selectedAlbum {
    for (final album in albums) {
      if (album.id == selectedAlbumId) return album;
    }
    return null;
  }

  bool get isBusy => isImporting || isSaving;
  bool get canContinue =>
      status == GalleryStatus.ready && background != null && !isBusy;

  GalleryState copyWith({
    GalleryStatus? status,
    List<GalleryAlbum>? albums,
    Object? selectedAlbumId = _unchanged,
    List<GalleryImage>? images,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    Object? background = _unchanged,
    List<GalleryImage>? additionalImages,
    List<String>? importedFilePaths,
    bool? isImporting,
    bool? isSaving,
    Object? errorMessage = _unchanged,
  }) {
    return GalleryState(
      status: status ?? this.status,
      albums: albums ?? this.albums,
      selectedAlbumId: identical(selectedAlbumId, _unchanged)
          ? this.selectedAlbumId
          : selectedAlbumId as String?,
      images: images ?? this.images,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      background: identical(background, _unchanged)
          ? this.background
          : background as GalleryImage?,
      additionalImages: additionalImages ?? this.additionalImages,
      importedFilePaths: importedFilePaths ?? this.importedFilePaths,
      isImporting: isImporting ?? this.isImporting,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
