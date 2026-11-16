import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photmix_app/features/editor/data/tflite_background_removal_service.dart';
import 'package:photmix_app/features/editor/domain/background_removal_service.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'photmix-background-removal-',
    );
  });

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'aplica la máscara de persona y conserva el tamaño de la imagen',
    () async {
      final image = img.Image(width: 2, height: 2, numChannels: 3);
      image.setPixelRgb(0, 0, 255, 0, 0);
      image.setPixelRgb(1, 0, 0, 255, 0);
      image.setPixelRgb(0, 1, 0, 0, 255);
      image.setPixelRgb(1, 1, 255, 255, 255);
      final source = File('${temporaryDirectory.path}/subject.png');
      await source.writeAsBytes(img.encodePng(image));
      final model = FakePersonSegmentationModel(
        inputWidth: 2,
        inputHeight: 2,
        mask: Float32List.fromList([0, 0.5, 1, 1]),
      );

      final resultBytes = await TfliteBackgroundRemovalService(
        model,
      ).removeBackground(source.path);
      final result = img.decodeImage(resultBytes)!;

      expect(result.width, 2);
      expect(result.height, 2);
      expect(result.getPixel(0, 0).a, 0);
      expect(result.getPixel(1, 0).a, closeTo(128, 1));
      expect(result.getPixel(0, 1).a, 255);
      expect(result.getPixel(1, 1).a, 255);
      expect(model.inputPixels, hasLength(12));
      expect(model.inputPixels!.first, closeTo(1, 0.01));
    },
  );
}

class FakePersonSegmentationModel implements PersonSegmentationModel {
  FakePersonSegmentationModel({
    required this.inputWidth,
    required this.inputHeight,
    required this.mask,
  });

  @override
  final int inputWidth;

  @override
  final int inputHeight;

  final Float32List mask;
  Float32List? inputPixels;

  @override
  Future<Float32List> predict(Float32List rgbPixels) async {
    inputPixels = rgbPixels;
    return mask;
  }
}
