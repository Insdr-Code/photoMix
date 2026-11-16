import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/background_removal_service.dart';

class TfliteBackgroundRemovalService implements BackgroundRemovalService {
  const TfliteBackgroundRemovalService(this._model);

  final PersonSegmentationModel _model;

  @override
  Future<Uint8List> removeBackground(String imagePath) async {
    final sourceBytes = await File(imagePath).readAsBytes();
    final prepared = await compute(_prepareImage, {
      'source': sourceBytes,
      'inputWidth': _model.inputWidth,
      'inputHeight': _model.inputHeight,
    });
    final mask = await _model.predict(prepared['pixels']! as Float32List);
    final maskWidth = _model.inputWidth;
    final maskHeight = _model.inputHeight;
    if (mask.length != maskWidth * maskHeight) {
      throw StateError('El modelo devolvió una máscara de tamaño inválido.');
    }

    return compute(_applyMask, {
      'source': sourceBytes,
      'mask': mask,
      'maskWidth': maskWidth,
      'maskHeight': maskHeight,
    });
  }
}

Map<String, Object> _prepareImage(Map<String, Object> request) {
  final bytes = request['source']! as Uint8List;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('El archivo no contiene una imagen válida.');
  }
  final source = img.bakeOrientation(decoded);
  final inputWidth = request['inputWidth']! as int;
  final inputHeight = request['inputHeight']! as int;
  final resized = img.copyResize(
    source,
    width: inputWidth,
    height: inputHeight,
    interpolation: img.Interpolation.linear,
  );
  final rgbPixels = Float32List(inputWidth * inputHeight * 3);
  var offset = 0;
  for (var y = 0; y < inputHeight; y++) {
    for (var x = 0; x < inputWidth; x++) {
      final pixel = resized.getPixel(x, y);
      rgbPixels[offset++] = pixel.rNormalized.toDouble();
      rgbPixels[offset++] = pixel.gNormalized.toDouble();
      rgbPixels[offset++] = pixel.bNormalized.toDouble();
    }
  }

  return {'pixels': rgbPixels};
}

Uint8List _applyMask(Map<String, Object> request) {
  final decoded = img.decodeImage(request['source']! as Uint8List);
  if (decoded == null) {
    throw const FormatException('El archivo no contiene una imagen válida.');
  }
  final source = img.bakeOrientation(decoded);
  final output = source.convert(numChannels: 4);
  final mask = request['mask']! as Float32List;
  final maskWidth = request['maskWidth']! as int;
  final maskHeight = request['maskHeight']! as int;
  final maxChannelValue = output.maxChannelValue;

  for (var y = 0; y < output.height; y++) {
    final maskY = output.height == 1
        ? 0.0
        : y * (maskHeight - 1) / (output.height - 1);
    final y0 = maskY.floor();
    final y1 = (y0 + 1).clamp(0, maskHeight - 1).toInt();
    final yFraction = maskY - y0;
    for (var x = 0; x < output.width; x++) {
      final maskX = output.width == 1
          ? 0.0
          : x * (maskWidth - 1) / (output.width - 1);
      final x0 = maskX.floor();
      final x1 = (x0 + 1).clamp(0, maskWidth - 1).toInt();
      final xFraction = maskX - x0;
      final top = _interpolate(
        mask[y0 * maskWidth + x0],
        mask[y0 * maskWidth + x1],
        xFraction,
      );
      final bottom = _interpolate(
        mask[y1 * maskWidth + x0],
        mask[y1 * maskWidth + x1],
        xFraction,
      );
      final confidence = _interpolate(top, bottom, yFraction);
      final alpha = confidence.isFinite
          ? (confidence.clamp(0.0, 1.0) * maxChannelValue).round()
          : 0;
      final pixel = output.getPixel(x, y);
      pixel.a = (pixel.a * alpha / maxChannelValue).round();
    }
  }

  return Uint8List.fromList(img.encodePng(output));
}

double _interpolate(double start, double end, double amount) {
  return start + (end - start) * amount;
}
