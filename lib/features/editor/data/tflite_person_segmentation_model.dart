import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../domain/background_removal_service.dart';

const _inputDimension = 257;
const _classCount = 21;
// DeepLab uses Pascal VOC label order, where person is class 15.
const _personClassIndex = 15;

class TflitePersonSegmentationModel implements PersonSegmentationModel {
  static const _modelPath = 'assets/models/deeplab_v3.tflite';

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;
  Future<void>? _initialization;

  @override
  int get inputWidth => _inputDimension;

  @override
  int get inputHeight => _inputDimension;

  @override
  Future<Float32List> predict(Float32List rgbPixels) async {
    final initialization = _initialization ??= _initialize();
    try {
      await initialization;
    } catch (_) {
      if (identical(_initialization, initialization)) {
        _initialization = null;
      }
      rethrow;
    }

    final interpreter = _interpreter!;
    final input = interpreter.getInputTensor(0);
    final expectedInputSize = inputWidth * inputHeight * 3;
    if (input.type != TensorType.float32 ||
        input.shape.join(',') != '1,257,257,3' ||
        rgbPixels.length != expectedInputSize) {
      throw StateError('El modelo de segmentación tiene una entrada inválida.');
    }

    final output = interpreter.getOutputTensor(0);
    if (output.type != TensorType.float32 ||
        output.shape.length != 4 ||
        output.shape.first != 1 ||
        output.shape.last != _classCount) {
      throw StateError('El modelo de segmentación tiene una salida inválida.');
    }
    if (output.shape[1] != inputHeight ||
        output.shape[2] != inputWidth ||
        output.numBytes() != output.numElements() * 4 ||
        output.numElements() != inputWidth * inputHeight * _classCount) {
      throw StateError('El modelo de segmentación tiene una salida inválida.');
    }

    final outputBytes = Uint8List(output.numBytes());
    await _isolateInterpreter!.run(rgbPixels.buffer, outputBytes.buffer);
    return compute(_personConfidenceMask, outputBytes);
  }

  Future<void> _initialize() async {
    final interpreter = await Interpreter.fromAsset(_modelPath);
    try {
      final isolateInterpreter = await IsolateInterpreter.create(
        address: interpreter.address,
        debugName: 'PhotoMixPersonSegmenter',
      );
      _interpreter = interpreter;
      _isolateInterpreter = isolateInterpreter;
    } catch (_) {
      interpreter.close();
      rethrow;
    }
  }

  Future<void> dispose() async {
    final initialization = _initialization;
    if (initialization != null) {
      try {
        await initialization;
      } catch (error, stackTrace) {
        debugPrint(
          'No se pudo inicializar el modelo antes de cerrarlo: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    await _isolateInterpreter?.close();
    _interpreter?.close();
    _isolateInterpreter = null;
    _interpreter = null;
  }
}

Float32List _personConfidenceMask(Uint8List scoreBytes) {
  final byteData = ByteData.sublistView(scoreBytes);
  final mask = Float32List(_inputDimension * _inputDimension);
  for (var pixelIndex = 0; pixelIndex < mask.length; pixelIndex++) {
    final offset = pixelIndex * _classCount;
    var maxScore = double.negativeInfinity;
    for (var classIndex = 0; classIndex < _classCount; classIndex++) {
      final score = byteData.getFloat32((offset + classIndex) * 4, Endian.host);
      if (!score.isFinite) {
        throw StateError('El modelo devolvió una puntuación no válida.');
      }
      maxScore = math.max(maxScore, score).toDouble();
    }

    var total = 0.0;
    var personScore = 0.0;
    for (var classIndex = 0; classIndex < _classCount; classIndex++) {
      final logit = byteData.getFloat32((offset + classIndex) * 4, Endian.host);
      final score = math.exp(logit - maxScore);
      total += score;
      if (classIndex == _personClassIndex) {
        personScore = score;
      }
    }
    mask[pixelIndex] = personScore / total;
  }
  return mask;
}
