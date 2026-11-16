import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_image_file_picker.dart';
import '../data/photo_manager_gallery_repository.dart';
import '../domain/gallery_repository.dart';
import 'gallery_controller.dart';
import 'gallery_state.dart';

export '../../../core/services/image_file_storage_provider.dart'
    show imageFileStorageProvider;

final galleryRepositoryProvider = Provider<GalleryRepository>(
  (ref) => PhotoManagerGalleryRepository(),
);

final imageFilePickerProvider = Provider<ImageFilePicker>(
  (ref) => const DeviceImageFilePicker(),
);

final galleryControllerProvider =
    NotifierProvider<GalleryController, GalleryState>(GalleryController.new);
