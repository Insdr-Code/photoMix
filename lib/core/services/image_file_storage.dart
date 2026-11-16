import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class ImageFileStorage {
  Future<List<String>> storeImages({
    required String projectId,
    required List<File> images,
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
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(documents.path, 'PhotoMix', 'projects', projectId, 'images'),
    );
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
}
