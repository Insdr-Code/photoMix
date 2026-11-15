import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class ImageFileStorage {
  Future<List<String>> storeImages({
    required String projectId,
    required List<File> images,
  });
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
}
