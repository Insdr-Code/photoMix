import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:photmix_app/features/editor/data/tflite_background_removal_service.dart';
import 'package:photmix_app/features/editor/data/tflite_person_segmentation_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ejecuta el modelo TFLite de personas en el dispositivo', (
    tester,
  ) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'photmix-tflite-integration-',
    );
    final model = TflitePersonSegmentationModel();
    try {
      final source = img.Image(width: 32, height: 32, numChannels: 3);
      final sourceFile = File('${temporaryDirectory.path}/source.png');
      await sourceFile.writeAsBytes(img.encodePng(source));

      final pngBytes = await TfliteBackgroundRemovalService(
        model,
      ).removeBackground(sourceFile.path);
      final result = img.decodeImage(pngBytes)!;

      expect(result.width, 32);
      expect(result.height, 32);
      expect(result.hasAlpha, isTrue);
    } finally {
      await model.dispose();
      await temporaryDirectory.delete(recursive: true);
    }
  });
}
