import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/editor_project.dart';
import '../../domain/image_layer.dart';

class CompositionPainter extends CustomPainter {
  const CompositionPainter({
    required this.project,
    required this.images,
    required this.selectedLayerId,
  });

  final EditorProject project;
  final Map<String, ui.Image> images;
  final String? selectedLayerId;

  @override
  void paint(Canvas canvas, Size size) {
    final renderScale = size.width / project.canvasWidth;
    canvas.save();
    canvas.scale(renderScale, renderScale);

    final canvasRect = Rect.fromLTWH(
      0,
      0,
      project.canvasWidth.toDouble(),
      project.canvasHeight.toDouble(),
    );
    final background = images[project.backgroundPath];
    if (background != null) {
      canvas.drawImageRect(
        background,
        _sourceRect(background),
        canvasRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    }

    for (final layer in project.orderedLayers) {
      if (!layer.visible) continue;
      final image = images[layer.imagePath];
      if (image == null) continue;
      _drawImageLayer(canvas, layer, image);
    }

    final selectedLayer = _selectedLayer();
    if (selectedLayer != null && selectedLayer.visible) {
      _drawSelection(canvas, selectedLayer, renderScale);
    }
    canvas.restore();
  }

  void _drawImageLayer(Canvas canvas, ImageLayer layer, ui.Image image) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: layer.displayWidth * layer.scale,
      height: layer.displayHeight * layer.scale,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(alpha: layer.opacity);

    canvas.save();
    _applyLayerTransform(canvas, layer);
    canvas.drawImageRect(image, _layerSourceRect(image, layer), rect, paint);
    canvas.restore();
  }

  void _drawSelection(Canvas canvas, ImageLayer layer, double renderScale) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: layer.displayWidth * layer.scale,
      height: layer.displayHeight * layer.scale,
    );
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / renderScale
      ..color = AppColors.primary;
    final handlePaint = Paint()..color = AppColors.primary;

    canvas.save();
    _applyLayerTransform(canvas, layer);
    canvas.drawRect(rect, borderPaint);
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas
        ..drawCircle(corner, 6 / renderScale, handlePaint)
        ..drawCircle(corner, 3 / renderScale, Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  void _applyLayerTransform(Canvas canvas, ImageLayer layer) {
    canvas
      ..translate(
        layer.positionX * project.canvasWidth,
        layer.positionY * project.canvasHeight,
      )
      ..rotate(layer.rotation);
  }

  ImageLayer? _selectedLayer() {
    for (final layer in project.layers) {
      if (layer.id == selectedLayerId) return layer;
    }
    return null;
  }

  Rect _sourceRect(ui.Image image) {
    return Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
  }

  Rect _layerSourceRect(ui.Image image, ImageLayer layer) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    return Rect.fromLTRB(
      width * layer.crop.left,
      height * layer.crop.top,
      width * (1 - layer.crop.right),
      height * (1 - layer.crop.bottom),
    );
  }

  @override
  bool shouldRepaint(covariant CompositionPainter oldDelegate) {
    return oldDelegate.project != project ||
        oldDelegate.selectedLayerId != selectedLayerId ||
        oldDelegate.images != images;
  }
}
