class LayerCrop {
  const LayerCrop({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  }) : assert(left >= 0 && left <= 0.9),
       assert(top >= 0 && top <= 0.9),
       assert(right >= 0 && right <= 0.9),
       assert(bottom >= 0 && bottom <= 0.9),
       assert(left + right <= 0.9),
       assert(top + bottom <= 0.9);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get widthFactor => 1 - left - right;
  double get heightFactor => 1 - top - bottom;
  bool get isEmpty => this == const LayerCrop();

  LayerCrop copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return LayerCrop(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LayerCrop &&
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(left, top, right, bottom);
}
