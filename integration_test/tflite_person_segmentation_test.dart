import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:photmix_app/features/editor/data/composition_renderer.dart';
import 'package:photmix_app/features/editor/data/tflite_background_removal_service.dart';
import 'package:photmix_app/features/editor/data/tflite_person_segmentation_model.dart';
import 'package:photmix_app/features/editor/domain/editor_project.dart';
import 'package:photmix_app/features/editor/domain/export_format.dart';

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

  testWidgets('exporta una imagen 4K en el dispositivo sin perder resolución', (
    tester,
  ) async {
    const width = 3840;
    const height = 2160;
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'photmix-export-integration-',
    );
    try {
      final backgroundPath = '${temporaryDirectory.path}/background.png';
      await File(backgroundPath).writeAsBytes(
        img.encodePng(img.Image(width: width, height: height, numChannels: 3)),
      );
      final outputPath = '${temporaryDirectory.path}/composition.png';
      final now = DateTime(2026);
      final project = EditorProject(
        id: 'integration',
        name: 'Integración',
        backgroundPath: backgroundPath,
        canvasWidth: width,
        canvasHeight: height,
        layers: const [],
        createdAt: now,
        updatedAt: now,
      );

      await const CompositionRenderer().render(
        project: project,
        format: ExportFormat.png,
        quality: 90,
        outputPath: outputPath,
      );

      final output = img.decodeImage(await File(outputPath).readAsBytes())!;
      expect(output.width, width);
      expect(output.height, height);
    } finally {
      await temporaryDirectory.delete(recursive: true);
    }
  });
}
