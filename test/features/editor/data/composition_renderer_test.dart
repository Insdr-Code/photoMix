import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:photmix_app/features/editor/data/composition_renderer.dart';
import 'package:photmix_app/features/editor/domain/editor_project.dart';
import 'package:photmix_app/features/editor/domain/export_format.dart';
import 'package:photmix_app/features/editor/domain/image_layer.dart';
import 'package:photmix_app/features/editor/domain/layer_crop.dart';

void main() {
  late Directory directory;
  late CompositionRenderer renderer;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('photmix-export-test');
    renderer = const CompositionRenderer();
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('renderiza en tamaño original con recorte, orden y opacidad', () async {
    final background = solidImage(24, 24, 255, 0, 0);
    final overlay = solidImage(8, 8, 0, 0, 255);
    final backgroundPath = await writeImage(
      directory,
      'background.png',
      background,
    );
    final overlayPath = await writeImage(directory, 'overlay.png', overlay);
    final outputPath = '${directory.path}/result.png';
    final project = projectWithBackground(backgroundPath, [
      ImageLayer(
        id: 'overlay',
        imagePath: overlayPath,
        width: 8,
        height: 8,
        crop: const LayerCrop(left: 0.25, right: 0.25),
        positionX: 0.5,
        positionY: 0.5,
        opacity: 0.5,
      ),
    ]);

    await renderer.render(
      project: project,
      format: ExportFormat.png,
      quality: 90,
      outputPath: outputPath,
    );

    final rendered = img.decodeImage(await File(outputPath).readAsBytes())!;
    expect(rendered.width, 24);
    expect(rendered.height, 24);
    final center = rendered.getPixel(12, 12);
    expect(center.r, closeTo(128, 2));
    expect(center.b, closeTo(128, 2));
    expect(rendered.getPixel(1, 1).r, 255);
  });

  test(
    'omite las capas ocultas y codifica JPG con la calidad solicitada',
    () async {
      final background = solidImage(20, 12, 12, 34, 56);
      final hidden = solidImage(6, 6, 255, 0, 0);
      final backgroundPath = await writeImage(
        directory,
        'background.png',
        background,
      );
      final hiddenPath = await writeImage(directory, 'hidden.png', hidden);
      final outputPath = '${directory.path}/result.jpg';
      final project = projectWithBackground(
        backgroundPath,
        [
          ImageLayer(
            id: 'hidden',
            imagePath: hiddenPath,
            width: 6,
            height: 6,
            visible: false,
          ),
        ],
        width: 20,
        height: 12,
      );

      await renderer.render(
        project: project,
        format: ExportFormat.jpg,
        quality: 82,
        outputPath: outputPath,
      );

      final bytes = await File(outputPath).readAsBytes();
      final rendered = img.decodeImage(bytes)!;
      expect(bytes.first, 0xff);
      expect(bytes[1], 0xd8);
      expect(rendered.width, 20);
      expect(rendered.height, 12);
      expect(rendered.getPixel(10, 6).r, closeTo(12, 8));
    },
  );

  test('respeta el orden Z y la rotación de las capas', () async {
    final background = solidImage(20, 20, 0, 0, 0);
    final greenLayer = solidImage(8, 8, 0, 255, 0);
    final redLayer = solidImage(8, 2, 255, 0, 0).convert(numChannels: 3);
    final backgroundPath = await writeImage(
      directory,
      'background.png',
      background,
    );
    final greenPath = await writeImage(directory, 'green.png', greenLayer);
    final redPath = await writeImage(directory, 'red.png', redLayer);
    final outputPath = '${directory.path}/result.png';

    await renderer.render(
      project: projectWithBackground(
        backgroundPath,
        [
          ImageLayer(
            id: 'red',
            imagePath: redPath,
            width: 8,
            height: 2,
            rotation: math.pi / 2,
            zIndex: 1,
          ),
          ImageLayer(
            id: 'green',
            imagePath: greenPath,
            width: 8,
            height: 8,
            zIndex: 0,
          ),
        ],
        width: 20,
        height: 20,
      ),
      format: ExportFormat.png,
      quality: 90,
      outputPath: outputPath,
    );

    final rendered = img.decodeImage(await File(outputPath).readAsBytes())!;
    expect(rendered.getPixel(10, 10).r, 255);
    expect(rendered.getPixel(10, 6).r, 255);
    expect(rendered.getPixel(6, 10).g, 255);
    expect(rendered.getPixel(8, 8).g, 255);
  });

  test('rechaza calidad JPG fuera del rango permitido', () async {
    expect(
      () async => renderer.render(
        project: projectWithBackground('missing.png', const []),
        format: ExportFormat.jpg,
        quality: 0,
        outputPath: '${directory.path}/invalid.jpg',
      ),
      throwsRangeError,
    );
  });

  test('conserva la resolución 4K al renderizar una composición', () async {
    const width = 3840;
    const height = 2160;
    final backgroundPath = await writeImage(
      directory,
      '4k-background.png',
      img.Image(width: width, height: height, numChannels: 3),
    );
    final outputPath = '${directory.path}/4k-result.png';

    await renderer.render(
      project: projectWithBackground(
        backgroundPath,
        const [],
        width: width,
        height: height,
      ),
      format: ExportFormat.png,
      quality: 90,
      outputPath: outputPath,
    );

    final output = img.decodeImage(await File(outputPath).readAsBytes())!;
    expect(output.width, width);
    expect(output.height, height);
  });
}

EditorProject projectWithBackground(
  String backgroundPath,
  List<ImageLayer> layers, {
  int width = 24,
  int height = 24,
}) {
  final now = DateTime(2026);
  return EditorProject(
    id: 'project',
    name: 'Test',
    backgroundPath: backgroundPath,
    canvasWidth: width,
    canvasHeight: height,
    layers: layers,
    createdAt: now,
    updatedAt: now,
  );
}

img.Image solidImage(int width, int height, int red, int green, int blue) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = red
      ..g = green
      ..b = blue
      ..a = 255;
  }
  return image;
}

Future<String> writeImage(
  Directory directory,
  String name,
  img.Image image,
) async {
  final path = '${directory.path}/$name';
  await File(path).writeAsBytes(img.encodePng(image));
  return path;
}
