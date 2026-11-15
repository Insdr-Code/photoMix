import 'dart:io';
import 'dart:typed_data';

import 'gallery_models.dart';

abstract interface class GalleryRepository {
  Future<bool> requestAccess();

  Future<void> openSettings();

  Future<List<GalleryAlbum>> getAlbums();

  Future<List<GalleryImage>> getImages({
    required String albumId,
    required int page,
    required int pageSize,
  });

  Future<Uint8List?> getThumbnail(GalleryImage image, {required int size});

  Future<File?> getImageFile(GalleryImage image);
}

abstract interface class ImageFilePicker {
  Future<List<File>> pickImages();
}
