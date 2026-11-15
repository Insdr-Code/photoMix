import 'dart:io';
import 'dart:typed_data';

import 'package:photmix_app/core/services/image_file_storage.dart';
import 'package:photmix_app/features/gallery/domain/gallery_models.dart';
import 'package:photmix_app/features/gallery/domain/gallery_repository.dart';

const testImages = [
  GalleryImage(id: 'background', name: 'Fondo.jpg', width: 1200, height: 800),
  GalleryImage(id: 'layer', name: 'Capa.png', width: 600, height: 600),
  GalleryImage(id: 'other', name: 'Otra.jpg', width: 900, height: 1200),
];

class FakeGalleryRepository implements GalleryRepository {
  FakeGalleryRepository({
    this.hasAccess = true,
    List<GalleryAlbum>? albums,
    Map<String, List<GalleryImage>>? imagesByAlbum,
  }) : albums =
           albums ??
           const [
             GalleryAlbum(id: 'all', name: 'Todas las fotos', imageCount: 3),
             GalleryAlbum(id: 'favorites', name: 'Favoritos', imageCount: 1),
           ],
       imagesByAlbum =
           imagesByAlbum ??
           {
             'all': testImages,
             'favorites': [testImages[1]],
           };

  bool hasAccess;
  final List<GalleryAlbum> albums;
  final Map<String, List<GalleryImage>> imagesByAlbum;
  int openSettingsCalls = 0;

  @override
  Future<bool> requestAccess() async => hasAccess;

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }

  @override
  Future<List<GalleryAlbum>> getAlbums() async => albums;

  @override
  Future<List<GalleryImage>> getImages({
    required String albumId,
    required int page,
    required int pageSize,
  }) async {
    final images = imagesByAlbum[albumId] ?? const <GalleryImage>[];
    final start = (page - 1) * pageSize;
    if (start >= images.length) return const [];
    return images.skip(start).take(pageSize).toList(growable: false);
  }

  @override
  Future<Uint8List?> getThumbnail(
    GalleryImage image, {
    required int size,
  }) async => null;

  @override
  Future<File?> getImageFile(GalleryImage image) async {
    return File('/mock/${image.id}.jpg');
  }
}

class FakeImageFilePicker implements ImageFilePicker {
  FakeImageFilePicker({this.files = const []});

  final List<File> files;

  @override
  Future<List<File>> pickImages() async => files;
}

class FakeImageFileStorage implements ImageFileStorage {
  String? projectId;
  List<String> sourcePaths = const [];

  @override
  Future<List<String>> storeImages({
    required String projectId,
    required List<File> images,
  }) async {
    this.projectId = projectId;
    sourcePaths = images.map((image) => image.path).toList(growable: false);
    return [
      for (var index = 0; index < images.length; index++)
        '/private/$projectId/${index.toString().padLeft(3, '0')}_${images[index].uri.pathSegments.last}',
    ];
  }
}
