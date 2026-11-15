import 'dart:math' as math;
import 'dart:ui';

import 'editor_project.dart';
import 'image_layer.dart';

abstract final class EditorGeometry {
  static ImageLayer? topLayerAt(EditorProject project, Offset normalizedPoint) {
    final layers = project.orderedLayers.reversed;
    for (final layer in layers) {
      if (!layer.visible) continue;
      if (_containsPoint(project, layer, normalizedPoint)) return layer;
    }
    return null;
  }

  static bool _containsPoint(
    EditorProject project,
    ImageLayer layer,
    Offset point,
  ) {
    final dx = (point.dx - layer.positionX) * project.canvasWidth;
    final dy = (point.dy - layer.positionY) * project.canvasHeight;
    final cosine = math.cos(layer.rotation);
    final sine = math.sin(layer.rotation);
    final localX = dx * cosine + dy * sine;
    final localY = -dx * sine + dy * cosine;

    return localX.abs() <= layer.displayWidth * layer.scale / 2 &&
        localY.abs() <= layer.displayHeight * layer.scale / 2;
  }
}
