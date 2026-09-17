import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../data/models/annotation.dart';

enum DrawingTool { freehand, circle, marker, pan, none }

/// Repaint notifier to trigger immediate CustomPainter repaints during gestures
class _RepaintNotifier extends ChangeNotifier {
  void requestRepaint() => notifyListeners();
}

/// Interactive drawing canvas for medical diagram annotations
class DrawingCanvas extends StatefulWidget {
  final List<String> diagramPaths; // [left, right] or [solo, solo] or [] for blank
  final List<Annotation> initialAnnotations;
  final ValueChanged<List<Annotation>> onAnnotationsChanged;
  final DrawingTool currentTool;
  final Color currentColor;
  final double strokeWidth;
  final String currentExamType;
  final bool readOnly;
  final double diagramScale;

  const DrawingCanvas({
    super.key,
    required this.diagramPaths,
    required this.initialAnnotations,
    required this.onAnnotationsChanged,
    required this.currentTool,
    required this.currentColor,
    required this.strokeWidth,
    required this.currentExamType,
    this.readOnly = false,
    this.diagramScale = 1.0,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  late List<Annotation> annotations;
  Offset? circleStart;
  Offset? circleEnd;
  List<Offset> currentFreehandPoints = [];
  ui.Image? leftImage;
  ui.Image? rightImage;

  final _repaintNotifier = _RepaintNotifier();

  @override
  void initState() {
    super.initState();
    annotations = List.from(widget.initialAnnotations);
    _loadDiagramImages();
  }

  @override
  void dispose() {
    _repaintNotifier.dispose();
    leftImage?.dispose();
    rightImage?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAnnotations != oldWidget.initialAnnotations) {
      annotations = List.from(widget.initialAnnotations);
    }
    if (widget.diagramPaths != oldWidget.diagramPaths) {
      _loadDiagramImages();
    }
    if (widget.currentTool != oldWidget.currentTool) {
      if (currentFreehandPoints.isNotEmpty) {
        currentFreehandPoints.clear();
        _repaintNotifier.requestRepaint();
      }
      if (circleStart != null || circleEnd != null) {
        circleStart = null;
        circleEnd = null;
        _repaintNotifier.requestRepaint();
      }
    }
  }

  Future<void> _loadDiagramImages() async {
    if (widget.diagramPaths.isEmpty) {
      if (mounted) {
        setState(() {
          leftImage = null;
          rightImage = null;
        });
      }
      return;
    }

    try {
      final isSoloDiagram = widget.diagramPaths.length == 1 ||
          widget.diagramPaths[0] == widget.diagramPaths[1];
      final assetBundle = DefaultAssetBundle.of(context);

      final leftData = await assetBundle.load(widget.diagramPaths[0]);
      final leftCodec = await ui.instantiateImageCodec(leftData.buffer.asUint8List());
      final leftFrame = await leftCodec.getNextFrame();

      if (isSoloDiagram) {
        if (mounted) {
          setState(() {
            leftImage = leftFrame.image;
            rightImage = null;
          });
        }
      } else {
        final rightData = await assetBundle.load(widget.diagramPaths[1]);
        final rightCodec = await ui.instantiateImageCodec(rightData.buffer.asUint8List());
        final rightFrame = await rightCodec.getNextFrame();

        if (mounted) {
          setState(() {
            leftImage = leftFrame.image;
            rightImage = rightFrame.image;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading diagram image: $e');
    }
  }

  void undo() {
    if (annotations.isNotEmpty) {
      setState(() {
        annotations.removeLast();
        widget.onAnnotationsChanged(annotations);
      });
    }
  }

  void clear() {
    if (annotations.isNotEmpty) {
      setState(() {
        annotations.clear();
        widget.onAnnotationsChanged(annotations);
      });
    }
  }

  void _handlePanStart(DragStartDetails details, Size canvasSize) {
    if (widget.readOnly || widget.currentTool == DrawingTool.pan) return;

    final localPos = details.localPosition;
    final normalizedX = localPos.dx / canvasSize.width;
    final normalizedY = localPos.dy / canvasSize.height;

    switch (widget.currentTool) {
      case DrawingTool.freehand:
        currentFreehandPoints = [Offset(normalizedX, normalizedY)];
        _repaintNotifier.requestRepaint();
        break;
      case DrawingTool.circle:
        circleStart = Offset(normalizedX, normalizedY);
        circleEnd = Offset(normalizedX, normalizedY);
        _repaintNotifier.requestRepaint();
        break;
      case DrawingTool.marker:
        final newMarker = MarkerAnnotation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          color: widget.currentColor,
          examType: widget.currentExamType,
          x: normalizedX,
          y: normalizedY,
          size: widget.strokeWidth * 3.5,
        );
        setState(() {
          annotations.add(newMarker);
          widget.onAnnotationsChanged(annotations);
        });
        break;
      case DrawingTool.pan:
      case DrawingTool.none:
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (widget.readOnly || widget.currentTool == DrawingTool.pan) return;

    final localPos = details.localPosition;
    final normalizedX = (localPos.dx / canvasSize.width).clamp(0.0, 1.0);
    final normalizedY = (localPos.dy / canvasSize.height).clamp(0.0, 1.0);

    switch (widget.currentTool) {
      case DrawingTool.freehand:
        currentFreehandPoints.add(Offset(normalizedX, normalizedY));
        _repaintNotifier.requestRepaint();
        break;
      case DrawingTool.circle:
        circleEnd = Offset(normalizedX, normalizedY);
        _repaintNotifier.requestRepaint();
        break;
      default:
        break;
    }
  }

  void _handlePanEnd(DragEndDetails details, Size canvasSize) {
    if (widget.readOnly || widget.currentTool == DrawingTool.pan) return;

    switch (widget.currentTool) {
      case DrawingTool.freehand:
        if (currentFreehandPoints.length > 1) {
          final newPath = FreehandAnnotation(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            color: widget.currentColor,
            examType: widget.currentExamType,
            points: List.from(currentFreehandPoints),
            strokeWidth: widget.strokeWidth,
          );
          setState(() {
            annotations.add(newPath);
            currentFreehandPoints.clear();
            widget.onAnnotationsChanged(annotations);
          });
        }
        break;
      case DrawingTool.circle:
        if (circleStart != null && circleEnd != null) {
          final dx = circleEnd!.dx - circleStart!.dx;
          final dy = circleEnd!.dy - circleStart!.dy;
          final radius = sqrt(dx * dx + dy * dy);

          if (radius > 0.005) {
            final newCircle = CircleAnnotation(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              color: widget.currentColor,
              examType: widget.currentExamType,
              x: circleStart!.dx,
              y: circleStart!.dy,
              radius: radius,
              strokeWidth: widget.strokeWidth,
            );
            setState(() {
              annotations.add(newCircle);
              circleStart = null;
              circleEnd = null;
              widget.onAnnotationsChanged(annotations);
            });
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (details) => _handlePanStart(details, canvasSize),
          onPanUpdate: (details) => _handlePanUpdate(details, canvasSize),
          onPanEnd: (details) => _handlePanEnd(details, canvasSize),
          child: CustomPaint(
            size: canvasSize,
            painter: _DiagramPainter(
              annotations: annotations,
              currentFreehandPoints: currentFreehandPoints,
              circleStart: circleStart,
              circleEnd: circleEnd,
              currentColor: widget.currentColor,
              strokeWidth: widget.strokeWidth,
              leftImage: leftImage,
              rightImage: rightImage,
              repaintNotifier: _repaintNotifier,
            ),
          ),
        );
      },
    );
  }
}

class _DiagramPainter extends CustomPainter {
  final List<Annotation> annotations;
  final List<Offset> currentFreehandPoints;
  final Offset? circleStart;
  final Offset? circleEnd;
  final Color currentColor;
  final double strokeWidth;
  final ui.Image? leftImage;
  final ui.Image? rightImage;

  _DiagramPainter({
    required this.annotations,
    required this.currentFreehandPoints,
    this.circleStart,
    this.circleEnd,
    required this.currentColor,
    required this.strokeWidth,
    this.leftImage,
    this.rightImage,
    required Listenable repaintNotifier,
  }) : super(repaint: repaintNotifier);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background Medical Diagrams
    if (leftImage != null) {
      if (rightImage == null) {
        // Solo diagram: center in canvas
        _drawImageFitted(canvas, leftImage!, Rect.fromLTWH(0, 0, size.width, size.height));
      } else {
        // Paired diagrams: left and right
        final halfWidth = size.width / 2;
        _drawImageFitted(canvas, leftImage!, Rect.fromLTWH(0, 0, halfWidth, size.height));
        _drawImageFitted(canvas, rightImage!, Rect.fromLTWH(halfWidth, 0, halfWidth, size.height));
      }
    }

    // 2. Draw Committed Annotations
    for (final annotation in annotations) {
      final paint = Paint()
        ..color = annotation.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (annotation is FreehandAnnotation) {
        paint.strokeWidth = annotation.strokeWidth;
        final path = Path();
        if (annotation.points.isNotEmpty) {
          path.moveTo(
            annotation.points.first.dx * size.width,
            annotation.points.first.dy * size.height,
          );
          for (int i = 1; i < annotation.points.length; i++) {
            path.lineTo(
              annotation.points[i].dx * size.width,
              annotation.points[i].dy * size.height,
            );
          }
          canvas.drawPath(path, paint);
        }
      } else if (annotation is CircleAnnotation) {
        paint.strokeWidth = annotation.strokeWidth;
        canvas.drawCircle(
          Offset(annotation.x * size.width, annotation.y * size.height),
          annotation.radius * size.width,
          paint,
        );
      } else if (annotation is MarkerAnnotation) {
        paint.style = PaintingStyle.fill;
        final center = Offset(annotation.x * size.width, annotation.y * size.height);
        // Outer pulsing ring
        final outerPaint = Paint()
          ..color = annotation.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, annotation.size, outerPaint);
        // Inner core
        canvas.drawCircle(center, annotation.size * 0.55, paint);
      }
    }

    // 3. Draw Active In-Progress Gesture
    if (currentFreehandPoints.isNotEmpty) {
      final activePaint = Paint()
        ..color = currentColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(
        currentFreehandPoints.first.dx * size.width,
        currentFreehandPoints.first.dy * size.height,
      );
      for (int i = 1; i < currentFreehandPoints.length; i++) {
        path.lineTo(
          currentFreehandPoints[i].dx * size.width,
          currentFreehandPoints[i].dy * size.height,
        );
      }
      canvas.drawPath(path, activePaint);
    }

    if (circleStart != null && circleEnd != null) {
      final activeCirclePaint = Paint()
        ..color = currentColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      final dx = circleEnd!.dx - circleStart!.dx;
      final dy = circleEnd!.dy - circleStart!.dy;
      final radius = sqrt(dx * dx + dy * dy);

      canvas.drawCircle(
        Offset(circleStart!.dx * size.width, circleStart!.dy * size.height),
        radius * size.width,
        activeCirclePaint,
      );
    }
  }

  void _drawImageFitted(Canvas canvas, ui.Image image, Rect destinationRect) {
    final imageRatio = image.width / image.height;
    final destRatio = destinationRect.width / destinationRect.height;

    double targetWidth;
    double targetHeight;

    if (imageRatio > destRatio) {
      targetWidth = destinationRect.width * 0.92;
      targetHeight = targetWidth / imageRatio;
    } else {
      targetHeight = destinationRect.height * 0.92;
      targetWidth = targetHeight * imageRatio;
    }

    final targetLeft = destinationRect.left + (destinationRect.width - targetWidth) / 2;
    final targetTop = destinationRect.top + (destinationRect.height - targetHeight) / 2;

    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(targetLeft, targetTop, targetWidth, targetHeight);

    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter oldDelegate) => true;
}
