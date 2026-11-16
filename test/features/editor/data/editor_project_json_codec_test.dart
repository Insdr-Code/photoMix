import 'package:flutter_test/flutter_test.dart';
import 'package:photmix_app/features/editor/data/editor_project_json_codec.dart';
import 'package:photmix_app/features/editor/domain/editor_project.dart';
import 'package:photmix_app/features/editor/domain/image_layer.dart';
import 'package:photmix_app/features/editor/domain/layer_crop.dart';

void main() {
  test('serializa y restaura el proyecto y todos sus atributos de capa', () {
    final createdAt = DateTime(2026, 11, 15, 10);
    final updatedAt = DateTime(2026, 11, 15, 11);
    final project = EditorProject(
      id: 'project-1',
      name: 'Composición',
      backgroundPath: '/images/background.jpg',
      canvasWidth: 1200,
      canvasHeight: 800,
      layers: const [
        ImageLayer(
          id: 'layer-1',
          imagePath: '/images/overlay.png',
          width: 400,
          height: 300,
          crop: LayerCrop(left: 0.1, top: 0.2, right: 0.15, bottom: 0.05),
          positionX: 0.42,
          positionY: 0.61,
          scale: 1.4,
          rotation: 0.35,
          opacity: 0.65,
          zIndex: 2,
          visible: false,
          locked: true,
        ),
      ],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final restored = EditorProjectJsonCodec.projectFromRow(
      EditorProjectJsonCodec.projectToRow(project),
    );

    expect(restored.id, project.id);
    expect(restored.name, project.name);
    expect(restored.backgroundPath, project.backgroundPath);
    expect(restored.canvasWidth, project.canvasWidth);
    expect(restored.canvasHeight, project.canvasHeight);
    expect(restored.createdAt, createdAt);
    expect(restored.updatedAt, updatedAt);
    expect(restored.layers, hasLength(1));
    final layer = restored.layers.single;
    expect(layer.id, 'layer-1');
    expect(layer.imagePath, '/images/overlay.png');
    expect(layer.width, 400);
    expect(layer.height, 300);
    expect(
      layer.crop,
      const LayerCrop(left: 0.1, top: 0.2, right: 0.15, bottom: 0.05),
    );
    expect(layer.positionX, 0.42);
    expect(layer.positionY, 0.61);
    expect(layer.scale, 1.4);
    expect(layer.rotation, 0.35);
    expect(layer.opacity, 0.65);
    expect(layer.zIndex, 2);
    expect(layer.visible, isFalse);
    expect(layer.locked, isTrue);
  });

  test('rechaza JSON de capas mal formado explícitamente', () {
    expect(
      () => EditorProjectJsonCodec.decodeLayers('{"layers":[]}'),
      throwsFormatException,
    );
    expect(
      () => EditorProjectJsonCodec.decodeLayers('[{"id":"layer"}]'),
      throwsFormatException,
    );
  });
}
