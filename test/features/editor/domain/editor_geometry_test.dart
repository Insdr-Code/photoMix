import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/features/editor/domain/editor_geometry.dart';
import 'package:photmix_app/features/editor/domain/editor_project.dart';
import 'package:photmix_app/features/editor/domain/image_layer.dart';

void main() {
  final now = DateTime(2026);

  EditorProject projectWithLayers(List<ImageLayer> layers) {
    return EditorProject(
      id: 'project',
      name: 'Prueba',
      backgroundPath: 'background.jpg',
      canvasWidth: 100,
      canvasHeight: 100,
      layers: layers,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('selecciona la capa visible superior en el punto tocado', () {
    const bottom = ImageLayer(
      id: 'bottom',
      imagePath: 'bottom.png',
      width: 80,
      height: 80,
      zIndex: 0,
    );
    const top = ImageLayer(
      id: 'top',
      imagePath: 'top.png',
      width: 80,
      height: 80,
      zIndex: 1,
      visible: false,
    );

    final hit = EditorGeometry.topLayerAt(
      projectWithLayers([bottom, top]),
      const Offset(0.5, 0.5),
    );

    expect(hit?.id, 'bottom');
    expect(
      EditorGeometry.topLayerAt(
        projectWithLayers([bottom, top]),
        const Offset(0.01, 0.01),
      ),
      isNull,
    );
  });

  test('considera la rotación al comprobar los límites', () {
    const layer = ImageLayer(
      id: 'layer',
      imagePath: 'layer.png',
      width: 40,
      height: 20,
      rotation: math.pi / 2,
    );
    final project = projectWithLayers([layer]);

    expect(
      EditorGeometry.topLayerAt(project, const Offset(0.5, 0.68))?.id,
      'layer',
    );
    expect(EditorGeometry.topLayerAt(project, const Offset(0.68, 0.5)), isNull);
  });
}
