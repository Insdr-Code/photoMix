import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import '../domain/gallery_models.dart';
import '../domain/gallery_repository.dart';

class PhotoManagerGalleryRepository implements GalleryRepository {
  final _albums = <String, AssetPathEntity>{};
  final _images = <String, AssetEntity>{};

  @override
  Future<bool> requestAccess() async {
    final permission = await PhotoManager.requestPermissionExtend();
    return permission.hasAccess;
  }

  @override
  Future<void> openSettings() => PhotoManager.openSetting();

  @override
  Future<List<GalleryAlbum>> getAlbums() async {
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );

    _albums
      ..clear()
      ..addEntries(paths.map((path) => MapEntry(path.id, path)));

    final albums = await Future.wait(
      paths.map((path) async {
        final count = await path.assetCountAsync;
        return GalleryAlbum(
          id: path.id,
          name: path.isAll ? 'Todas las fotos' : path.name,
          imageCount: count,
        );
      }),
    );
    return albums
        .where((album) => album.imageCount > 0)
        .toList(growable: false);
  }

  @override
  Future<List<GalleryImage>> getImages({
    required String albumId,
    required int page,
    required int pageSize,
  }) async {
    final album = _albums[albumId];
    if (album == null || page < 1) return const [];

    final start = (page - 1) * pageSize;
    final imageCount = await album.assetCountAsync;
    if (start >= imageCount) return const [];

    final assets = await album.getAssetListRange(
      start: start,
      end: math.min(start + pageSize, imageCount),
    );
    final images = assets.map(_toGalleryImage).toList(growable: false);
    _images.addEntries(
      images.map((image) {
        final asset = assets.firstWhere((asset) => asset.id == image.id);
        return MapEntry(image.id, asset);
      }),
    );
    return images;
  }

  @override
  Future<Uint8List?> getThumbnail(GalleryImage image, {required int size}) {
    final asset = _images[image.id];
    if (asset == null) return Future.value();
    return asset.thumbnailDataWithSize(ThumbnailSize.square(size), quality: 85);
  }

  @override
  Future<File?> getImageFile(GalleryImage image) async {
    final asset = _images[image.id];
    if (asset == null) return null;
    return await asset.originFile ?? await asset.file;
  }

  GalleryImage _toGalleryImage(AssetEntity asset) {
    return GalleryImage(
      id: asset.id,
      name: asset.title ?? 'Fotografía',
      width: asset.width,
      height: asset.height,
    );
  }
}
