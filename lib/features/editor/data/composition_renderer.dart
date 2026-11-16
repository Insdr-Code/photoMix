import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import '../domain/editor_project.dart';
import '../domain/export_format.dart';
import '../domain/image_layer.dart';

class CompositionRenderer {
  const CompositionRenderer();

  Future<void> render({
    required EditorProject project,
    required ExportFormat format,
    required int quality,
    required String outputPath,
  }) async {
    if (format == ExportFormat.jpg && (quality < 1 || quality > 100)) {
      throw RangeError.range(quality, 1, 100, 'quality');
    }

    final request = <String, Object>{
      'backgroundPath': project.backgroundPath,
      'width': project.canvasWidth,
      'height': project.canvasHeight,
      'outputPath': outputPath,
      'format': format.name,
      'quality': quality,
      'layers': project.orderedLayers
          .where((layer) => layer.visible)
          .map(_serializeLayer)
          .toList(growable: false),
    };
    await Isolate.run(() => _renderComposition(request));
  }

  Map<String, Object> _serializeLayer(ImageLayer layer) {
    return {
      'path': layer.imagePath,
      'positionX': layer.positionX,
      'positionY': layer.positionY,
      'width': layer.width,
      'height': layer.height,
      'cropLeft': layer.crop.left,
      'cropTop': layer.crop.top,
      'cropRight': layer.crop.right,
      'cropBottom': layer.crop.bottom,
      'scale': layer.scale,
      'rotation': layer.rotation,
      'opacity': layer.opacity,
    };
  }
}

Future<String> _renderComposition(Map<String, Object> request) async {
  final backgroundPath = request['backgroundPath']! as String;
  final background = await _decodeImage(backgroundPath);
  final width = request['width']! as int;
  final height = request['height']! as int;
  if (background.width != width || background.height != height) {
    throw StateError('El tamaño del fondo no coincide con el proyecto.');
  }

  final format = ExportFormat.values.byName(request['format']! as String);
  final canvas = format == ExportFormat.jpg
      ? img.Image(width: width, height: height, numChannels: 4)
      : background.convert(numChannels: 4);
  if (format == ExportFormat.jpg) {
    img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));
    img.compositeImage(canvas, background);
  }

  final layers = request['layers']! as List<Object>;
  for (final serializedLayer in layers) {
    final layer = serializedLayer as Map<Object?, Object?>;
    await _compositeLayer(canvas, layer);
  }

  final outputPath = request['outputPath']! as String;
  final outputFile = File(outputPath);
  await outputFile.parent.create(recursive: true);
  final encoded = switch (format) {
    ExportFormat.png => img.encodePng(canvas),
    ExportFormat.jpg => img.encodeJpg(
      canvas,
      quality: request['quality']! as int,
    ),
  };
  await outputFile.writeAsBytes(encoded, flush: true);
  return outputPath;
}

Future<img.Image> _decodeImage(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw FormatException('No se pudo decodificar la imagen: $path');
  }
  return img.bakeOrientation(decoded);
}

Future<void> _compositeLayer(
  img.Image canvas,
  Map<Object?, Object?> layer,
) async {
  final source = await _decodeImage(layer['path']! as String);
  final left = ((layer['cropLeft']! as num) * source.width).round();
  final top = ((layer['cropTop']! as num) * source.height).round();
  final right = ((layer['cropRight']! as num) * source.width).round();
  final bottom = ((layer['cropBottom']! as num) * source.height).round();
  final cropWidth = math.max(1, source.width - left - right);
  final cropHeight = math.max(1, source.height - top - bottom);
  final cropped = img.copyCrop(
    source,
    x: left,
    y: top,
    width: cropWidth,
    height: cropHeight,
  );
  final displayWidth = math.max(
    1,
    ((layer['width']! as num) *
            (1 - (layer['cropLeft']! as num) - (layer['cropRight']! as num)) *
            (layer['scale']! as num))
        .round(),
  );
  final displayHeight = math.max(
    1,
    ((layer['height']! as num) *
            (1 - (layer['cropTop']! as num) - (layer['cropBottom']! as num)) *
            (layer['scale']! as num))
        .round(),
  );
  var rendered = img.copyResize(
    cropped,
    width: displayWidth,
    height: displayHeight,
    interpolation: img.Interpolation.linear,
  );
  final rotation = layer['rotation']! as num;
  if (rotation != 0) {
    rendered = rendered.convert(numChannels: 4);
    rendered = img.copyRotate(
      rendered,
      angle: rotation * 180 / math.pi,
      interpolation: img.Interpolation.linear,
    );
  }

  final opacity = layer['opacity']! as num;
  if (opacity < 1) {
    if (rendered.numChannels != 4) {
      rendered = rendered.convert(numChannels: 4);
    }
    for (final pixel in rendered) {
      pixel.a = (pixel.a * opacity).round();
    }
  }

  final x =
      ((layer['positionX']! as num) * canvas.width).round() -
      rendered.width ~/ 2;
  final y =
      ((layer['positionY']! as num) * canvas.height).round() -
      rendered.height ~/ 2;
  img.compositeImage(canvas, rendered, dstX: x, dstY: y);
}
