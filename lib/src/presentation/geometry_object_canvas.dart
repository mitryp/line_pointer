import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syntax_analyzer/syntax_analyzer.dart';

class GeometryObjectCanvas extends StatelessWidget {
  final Iterable<GeometryObject> geometryObjects;

  const GeometryObjectCanvas({required this.geometryObjects, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: GeometryObjectPainter(
          geometryObjects
        ),
      ),
    );
  }
}

class GeometryObjectPainter extends CustomPainter {
  static const double _pointStrokeWidth = 8;
  static const double _lineStrokeWidth = 2;
  static const Offset _pointLabelOffset =
      Offset(8 - _pointStrokeWidth / 2, 10 - _pointStrokeWidth + 1);

  // static const Offset _lineLabelOffset =
  //     Offset(8 - _pointStrokeWidth / 2, 10 - _pointStrokeWidth + 1);
  static const double _unitToPixels = 25;
  static const Color _pointColor = Colors.red;
  static const Color _lineColor = Colors.blueAccent;

  final Iterable<GeometryObject> objects;

  const GeometryObjectPainter(this.objects);

  @override
  void paint(Canvas canvas, Size size) {
    Offset offsetTransform(Coordinates coords) {
      final Size(:width, :height) = size;
      final Coordinates(:x, :y) = coords;

      final xOrigin = width / 4;
      final yOrigin = height / 4;

      final oX = xOrigin + x * _unitToPixels;
      final oY = yOrigin - y * _unitToPixels;

      return Offset(xOrigin + oX, yOrigin + oY);
    }

    int count = 0;
    final namesToObjects = Map.fromEntries(objects.map((o) {
      count++;
      final declName = o.declaration.name;
      final name = declName.isEmpty ? '${o.declaration.type.name}$count' : declName;

      return MapEntry(name, o);
    }));

    _drawLines(canvas, size, objects.whereType<Line>(), offsetTransform, namesToObjects);

    _drawPoints(canvas, size, objects.whereType<Point>(), offsetTransform, namesToObjects);
  }

  void _drawPoints(
    Canvas canvas,
    Size size,
    Iterable<Point> points,
    Offset Function(Coordinates) offsetTransform,
    Map<String, GeometryObject> namesToObjects,
  ) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _pointStrokeWidth
      ..color = _pointColor;

    canvas.drawPoints(
      PointMode.points,
      points.map((p) => offsetTransform(p.coordinates!)).toList(growable: false),
      paint,
    );

    for (final MapEntry(key: name, value: point)
        in namesToObjects.entries.where((e) => points.contains(e.value))) {
      final coords = (point as Point).coordinates;
      if (coords == null) {
        continue;
      }

      final offset = offsetTransform(coords) + _pointLabelOffset;

      final textPaint = TextPainter(
        text:
            TextSpan(text: name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.justify,
      )..layout(maxWidth: size.width);

      textPaint.paint(canvas, offset);
    }
  }

  void _drawLines(
    Canvas canvas,
    Size size,
    Iterable<Line> lines,
    Offset Function(Coordinates) offsetTransform,
    Map<String, GeometryObject> namesToObjects,
  ) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _lineStrokeWidth
      ..color = _lineColor;

    (Coordinates, Coordinates) lineEdges(Coordinates c1, Coordinates c2) {
      const limX = 20;
      const limY = 20;

      final Coordinates(x: x1, y: y1) = c1;
      final Coordinates(x: x2, y: y2) = c2;

      return (
        Coordinates(
          (limX - x1) ~/ (x2 - x1),
          (limY - y1) ~/ (y2 - y1),
        ),
        Coordinates(
          (-limX - x1) ~/ (x2 - x1),
          (-limY - y1) ~/ (y2 - y1),
        )
      );
    }

    for (final line in lines) {
      final (p1Name, p2Name) = line.pointIds;

      if (p1Name == null || p2Name == null) continue;

      final p1 = offsetTransform((namesToObjects[p1Name] as Point).coordinates!);
      final p2 = offsetTransform((namesToObjects[p2Name] as Point).coordinates!);

      canvas.drawLine(p1, p2, paint);

      // todo
      // final (p1, p2) = lineEdges(
      //   (namesToObjects[p1Name] as Point).coordinates!,
      //   (namesToObjects[p2Name] as Point).coordinates!,
      // );

      // canvas.drawLine(offsetTransform(p1), offsetTransform(p2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GeometryObjectPainter oldDelegate) => objects != oldDelegate.objects;
}
