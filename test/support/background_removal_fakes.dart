import 'dart:typed_data';

import 'package:photmix_app/features/editor/domain/background_removal_service.dart';

class FakeBackgroundRemovalService implements BackgroundRemovalService {
  Uint8List result = Uint8List.fromList([1, 2, 3]);
  Object? failure;
  final sourcePaths = <String>[];

  @override
  Future<Uint8List> removeBackground(String imagePath) async {
    sourcePaths.add(imagePath);
    if (failure case final error?) throw error;
    return result;
  }
}
