class ImageLayer {
  const ImageLayer({
    required this.id,
    required this.imagePath,
    required this.width,
    required this.height,
    this.positionX = 0.5,
    this.positionY = 0.5,
    this.scale = 1,
    this.rotation = 0,
    this.opacity = 1,
    this.zIndex = 0,
    this.visible = true,
    this.locked = false,
  }) : assert(width > 0),
       assert(height > 0),
       assert(scale > 0),
       assert(opacity >= 0 && opacity <= 1);

  final String id;
  final String imagePath;

  /// Centro horizontal normalizado respecto al ancho del lienzo.
  final double positionX;

  /// Centro vertical normalizado respecto al alto del lienzo.
  final double positionY;

  /// Dimensiones originales de la imagen en píxeles.
  final double width;
  final double height;
  final double scale;

  /// Rotación en radianes.
  final double rotation;
  final double opacity;
  final int zIndex;
  final bool visible;
  final bool locked;

  ImageLayer copyWith({
    String? id,
    String? imagePath,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    double? scale,
    double? rotation,
    double? opacity,
    int? zIndex,
    bool? visible,
    bool? locked,
  }) {
    return ImageLayer(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      width: width ?? this.width,
      height: height ?? this.height,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      visible: visible ?? this.visible,
      locked: locked ?? this.locked,
    );
  }
}
