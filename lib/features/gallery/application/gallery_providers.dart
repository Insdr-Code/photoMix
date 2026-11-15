import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_file_storage.dart';
import '../data/device_image_file_picker.dart';
import '../data/photo_manager_gallery_repository.dart';
import '../domain/gallery_repository.dart';
import 'gallery_controller.dart';
import 'gallery_state.dart';

final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => PhotoManagerGalleryRepository(),
);

final imageFilePickerProvider = Provider<ImageFilePicker>(
  (ref) => const DeviceImageFilePicker(),
);

final imageFileStorageProvider = Provider<ImageFileStorage>(
  (ref) => const LocalImageFileStorage(),
);

final galleryControllerProvider =
    NotifierProvider<GalleryController, GalleryState>(GalleryController.new);
