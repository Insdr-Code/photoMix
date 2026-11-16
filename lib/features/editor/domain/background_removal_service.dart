import 'dart:typed_data';

abstract interface class BackgroundRemovalService {
  Future<Uint8List> removeBackground(String imagePath);
}

abstract interface class PersonSegmentationModel {
  int get inputWidth;

  int get inputHeight;

  /// Receives flattened RGB pixels normalized to [0, 1].
  Future<Float32List> predict(Float32List rgbPixels);
}
