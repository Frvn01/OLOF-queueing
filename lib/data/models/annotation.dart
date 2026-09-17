import 'dart:ui';

/// Round coordinates to 4 decimal places to reduce JSON storage size
double _roundCoord(double value) {
  return (value * 10000).round() / 10000;
}

/// Base class for all annotation types
abstract class Annotation {
  final String id;
  final Color color;
  final String? examType;

  Annotation({
    required this.id,
    required this.color,
    this.examType,
  });

  Map<String, dynamic> toJson();

  factory Annotation.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'freehand';
    switch (type) {
      case 'circle':
        return CircleAnnotation.fromJson(json);
      case 'marker':
        return MarkerAnnotation.fromJson(json);
      case 'freehand':
      default:
        return FreehandAnnotation.fromJson(json);
    }
  }
}

/// Circle annotation - x, y, radius normalized to 0..1
class CircleAnnotation extends Annotation {
  final double x;
  final double y;
  final double radius;
  final double strokeWidth;

  CircleAnnotation({
    required super.id,
    required super.color,
    super.examType,
    required this.x,
    required this.y,
    required this.radius,
    this.strokeWidth = 3.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'circle',
        'id': id,
        'color': color.toARGB32(),
        'examType': examType,
        'x': _roundCoord(x),
        'y': _roundCoord(y),
        'radius': _roundCoord(radius),
        'strokeWidth': _roundCoord(strokeWidth),
      };

  factory CircleAnnotation.fromJson(Map<String, dynamic> json) {
    return CircleAnnotation(
      id: json['id']?.toString() ?? '',
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFF0000),
      examType: json['examType']?.toString(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      radius: (json['radius'] as num?)?.toDouble() ?? 0.05,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
    );
  }
}

/// Marker (point / focal finding) annotation - x, y normalized to 0..1
class MarkerAnnotation extends Annotation {
  final double x;
  final double y;
  final String? label;
  final double size;

  MarkerAnnotation({
    required super.id,
    required super.color,
    super.examType,
    required this.x,
    required this.y,
    this.label,
    this.size = 12.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'marker',
        'id': id,
        'color': color.toARGB32(),
        'examType': examType,
        'x': _roundCoord(x),
        'y': _roundCoord(y),
        'label': label,
        'size': _roundCoord(size),
      };

  factory MarkerAnnotation.fromJson(Map<String, dynamic> json) {
    return MarkerAnnotation(
      id: json['id']?.toString() ?? '',
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFF0000),
      examType: json['examType']?.toString(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      label: json['label']?.toString(),
      size: (json['size'] as num?)?.toDouble() ?? 12.0,
    );
  }
}

/// Freehand path annotation - points normalized to 0..1
class FreehandAnnotation extends Annotation {
  final List<Offset> points;
  final double strokeWidth;

  FreehandAnnotation({
    required super.id,
    required super.color,
    super.examType,
    required this.points,
    this.strokeWidth = 3.0,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'freehand',
        'id': id,
        'color': color.toARGB32(),
        'examType': examType,
        'points': points
            .map((p) => {'x': _roundCoord(p.dx), 'y': _roundCoord(p.dy)})
            .toList(),
        'strokeWidth': _roundCoord(strokeWidth),
      };

  factory FreehandAnnotation.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List? ?? [];
    final pointsList = rawPoints.map((p) {
      final map = p as Map<String, dynamic>;
      return Offset(
        (map['x'] as num?)?.toDouble() ?? 0.0,
        (map['y'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    return FreehandAnnotation(
      id: json['id']?.toString() ?? '',
      color: Color((json['color'] as num?)?.toInt() ?? 0xFFFF0000),
      examType: json['examType']?.toString(),
      points: pointsList,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
    );
  }
}
