import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../domain/gallery_repository.dart';

class DeviceImageFilePicker implements ImageFilePicker {
  const DeviceImageFilePicker();

  @override
  Future<List<File>> pickImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);

    return files
        .map((file) => file.path)
        .whereType<String>()
        .map(File.new)
        .toList(growable: false);
  }
}
