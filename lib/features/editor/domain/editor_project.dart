import 'image_layer.dart';

class EditorProject {
  const EditorProject({
    required this.id,
    required this.name,
    required this.backgroundPath,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.layers,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(canvasWidth > 0),
       assert(canvasHeight > 0);

  final String id;
  final String name;
  final String backgroundPath;
  final int canvasWidth;
  final int canvasHeight;
  final List<ImageLayer> layers;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<ImageLayer> get orderedLayers {
    return [...layers]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  EditorProject copyWith({
    String? name,
    String? backgroundPath,
    int? canvasWidth,
    int? canvasHeight,
    List<ImageLayer>? layers,
    DateTime? updatedAt,
  }) {
    return EditorProject(
      id: id,
      name: name ?? this.name,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      layers: layers ?? this.layers,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
