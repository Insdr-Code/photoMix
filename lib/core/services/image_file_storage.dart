import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

abstract interface class ImageFileStorage {
  Future<List<String>> storeImages({
    required String projectId,
    required List<File> images,
  });

  Future<String> storeProcessedImage({
    required String projectId,
    required Uint8List pngBytes,
  });

  Future<void> deleteProjectImages(String projectId);
}

class LocalImageFileStorage implements ImageFileStorage {
  const LocalImageFileStorage();

  @override
  Future<List<String>> storeImages({
    required String projectId,
    required List<File> images,
  }) async {
    final directory = await _imagesDirectory(projectId);
    await directory.create(recursive: true);

    final storedPaths = <String>[];
    for (var index = 0; index < images.length; index++) {
      final sourceName = p.basename(images[index].path);
      final prefix = index.toString().padLeft(3, '0');
      final destination = File(p.join(directory.path, '${prefix}_$sourceName'));
      final storedImage = await images[index].copy(destination.path);
      storedPaths.add(storedImage.path);
    }
    return storedPaths;
  }

  @override
  Future<String> storeProcessedImage({
    required String projectId,
    required Uint8List pngBytes,
  }) async {
    final directory = await _imagesDirectory(projectId);
    await directory.create(recursive: true);
    final filename = 'background_removed_${const Uuid().v4()}.png';
    final file = File(p.join(directory.path, filename));
    await file.writeAsBytes(pngBytes, flush: true);
    return file.path;
  }

  @override
  Future<void> deleteProjectImages(String projectId) async {
    final documents = await getApplicationDocumentsDirectory();
    final root = p.normalize(p.join(documents.path, 'PhotoMix', 'projects'));
    if (projectId.isEmpty || p.basename(projectId) != projectId) {
      throw ArgumentError.value(projectId, 'projectId');
    }

    final projectDirectory = p.normalize(p.join(root, projectId));
    if (!p.isWithin(root, projectDirectory)) {
      throw ArgumentError.value(projectId, 'projectId');
    }

    final directory = Directory(projectDirectory);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<Directory> _imagesDirectory(String projectId) async {
    if (projectId.isEmpty || p.basename(projectId) != projectId) {
      throw ArgumentError.value(projectId, 'projectId');
    }
    final documents = await getApplicationDocumentsDirectory();
    return Directory(
      p.join(documents.path, 'PhotoMix', 'projects', projectId, 'images'),
    );
  }
}
