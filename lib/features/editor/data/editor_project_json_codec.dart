import 'dart:convert';

import '../domain/editor_project.dart';
import '../domain/image_layer.dart';
import '../domain/layer_crop.dart';

abstract final class EditorProjectJsonCodec {
  static String encodeLayers(List<ImageLayer> layers) {
    return jsonEncode(layers.map(_layerToJson).toList(growable: false));
  }

  static List<ImageLayer> decodeLayers(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const FormatException('Las capas del proyecto no son una lista.');
    }
    return decoded
        .map((value) {
          if (value is! Map<String, dynamic>) {
            throw const FormatException('Una capa del proyecto no es válida.');
          }
          return _layerFromJson(value);
        })
        .toList(growable: false);
  }

  static Map<String, Object> projectToRow(EditorProject project) {
    return {
      'id': project.id,
      'name': project.name,
      'background_path': project.backgroundPath,
      'canvas_width': project.canvasWidth,
      'canvas_height': project.canvasHeight,
      'layers_json': encodeLayers(project.layers),
      'created_at': project.createdAt.toIso8601String(),
      'updated_at': project.updatedAt.toIso8601String(),
    };
  }

  static EditorProject projectFromRow(Map<String, Object?> row) {
    final width = row['canvas_width'];
    final height = row['canvas_height'];
    if (width is! int || height is! int) {
      throw const FormatException(
        'Las dimensiones del proyecto no son válidas.',
      );
    }
    return EditorProject(
      id: _string(row, 'id'),
      name: _string(row, 'name'),
      backgroundPath: _string(row, 'background_path'),
      canvasWidth: width,
      canvasHeight: height,
      layers: decodeLayers(_string(row, 'layers_json')),
      createdAt: DateTime.parse(_string(row, 'created_at')),
      updatedAt: DateTime.parse(_string(row, 'updated_at')),
    );
  }

  static Map<String, Object> _layerToJson(ImageLayer layer) {
    return {
      'id': layer.id,
      'imagePath': layer.imagePath,
      'width': layer.width,
      'height': layer.height,
      'crop': {
        'left': layer.crop.left,
        'top': layer.crop.top,
        'right': layer.crop.right,
        'bottom': layer.crop.bottom,
      },
      'positionX': layer.positionX,
      'positionY': layer.positionY,
      'scale': layer.scale,
      'rotation': layer.rotation,
      'opacity': layer.opacity,
      'zIndex': layer.zIndex,
      'visible': layer.visible,
      'locked': layer.locked,
    };
  }

  static ImageLayer _layerFromJson(Map<String, dynamic> json) {
    final crop = json['crop'];
    if (crop is! Map<String, dynamic>) {
      throw const FormatException('El recorte de una capa no es válido.');
    }
    return ImageLayer(
      id: _string(json, 'id'),
      imagePath: _string(json, 'imagePath'),
      width: _number(json, 'width'),
      height: _number(json, 'height'),
      crop: LayerCrop(
        left: _number(crop, 'left'),
        top: _number(crop, 'top'),
        right: _number(crop, 'right'),
        bottom: _number(crop, 'bottom'),
      ),
      positionX: _number(json, 'positionX'),
      positionY: _number(json, 'positionY'),
      scale: _number(json, 'scale'),
      rotation: _number(json, 'rotation'),
      opacity: _number(json, 'opacity'),
      zIndex: _integer(json, 'zIndex'),
      visible: _boolean(json, 'visible'),
      locked: _boolean(json, 'locked'),
    );
  }

  static String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String) {
      throw FormatException('El campo "$key" debe ser texto.');
    }
    return value;
  }

  static double _number(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! num || !value.isFinite) {
      throw FormatException('El campo "$key" debe ser numérico.');
    }
    return value.toDouble();
  }

  static int _integer(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! int) {
      throw FormatException('El campo "$key" debe ser entero.');
    }
    return value;
  }

  static bool _boolean(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! bool) {
      throw FormatException('El campo "$key" debe ser booleano.');
    }
    return value;
  }
}
