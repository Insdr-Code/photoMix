import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'image_file_storage.dart';

final imageFileStorageProvider = Provider<ImageFileStorage>(
  (ref) => const LocalImageFileStorage(),
);
