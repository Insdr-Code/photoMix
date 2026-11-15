import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/editor_project.dart';
import '../painters/composition_painter.dart';

class CompositionCanvas extends StatefulWidget {
  const CompositionCanvas({
    required this.project,
    required this.images,
    required this.selectedLayerId,
    required this.onSelect,
    required this.onTransformStart,
    required this.onTransformUpdate,
    super.key,
  });

  final EditorProject project;
  final Map<String, ui.Image> images;
  final String? selectedLayerId;
  final ValueChanged<Offset> onSelect;
  final ValueChanged<Offset> onTransformStart;
  final void Function(Offset delta, double scale, double rotation)
  onTransformUpdate;

  @override
  State<CompositionCanvas> createState() => _CompositionCanvasState();
}

class _CompositionCanvasState extends State<CompositionCanvas> {
  Offset _startFocalPoint = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = _canvasSize(constraints);
        return Center(
          child: SizedBox(
            width: canvasSize.width,
            height: canvasSize.height,
            child: GestureDetector(
              key: const Key('composition-canvas'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                widget.onSelect(_normalize(details.localPosition, canvasSize));
              },
              onScaleStart: (details) {
                _startFocalPoint = details.localFocalPoint;
                widget.onTransformStart(
                  _normalize(details.localFocalPoint, canvasSize),
                );
              },
              onScaleUpdate: (details) {
                final focalDelta = (details.localFocalPoint - _startFocalPoint);
                widget.onTransformUpdate(
                  Offset(
                    focalDelta.dx / canvasSize.width,
                    focalDelta.dy / canvasSize.height,
                  ),
                  details.scale,
                  details.rotation,
                );
              },
              child: RepaintBoundary(
                child: ClipRect(
                  child: CustomPaint(
                    size: canvasSize,
                    painter: CompositionPainter(
                      project: widget.project,
                      images: widget.images,
                      selectedLayerId: widget.selectedLayerId,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Size _canvasSize(BoxConstraints constraints) {
    final aspectRatio =
        widget.project.canvasWidth / widget.project.canvasHeight;
    var width = constraints.maxWidth;
    var height = width / aspectRatio;
    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    }
    return Size(width, height);
  }

  Offset _normalize(Offset point, Size canvasSize) {
    return Offset(point.dx / canvasSize.width, point.dy / canvasSize.height);
  }
}
