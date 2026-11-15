class GalleryAlbum {
  const GalleryAlbum({
    required this.id,
    required this.name,
    required this.imageCount,
  });

  final String id;
  final String name;
  final int imageCount;
}

class GalleryImage {
  const GalleryImage({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
  });

  final String id;
  final String name;
  final int width;
  final int height;
}

class PhotoSelection {
  const PhotoSelection({
    required this.projectId,
    required this.backgroundPath,
    required this.additionalImagePaths,
  });

  final String projectId;
  final String backgroundPath;
  final List<String> additionalImagePaths;
}
