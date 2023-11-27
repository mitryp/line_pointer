import 'dart:math';

import 'package:flutter/material.dart';
import 'package:line_pointer/src/presentation/geometry_object_canvas.dart';
import 'package:syntax_analyzer/syntax_analyzer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _input;

  Iterable<GeometryObject> _parserOutput = [];

  void _onInputChanged(String text) {
    if (_input?.trim() == text.trim()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);

    _input = text;
    try {
      final output = analyze(text);

      if (output != _parserOutput) {
        setState(() {
          _parserOutput = _assignCoordinates(output);
        });
      }
    } on Error catch (err) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('$err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final display = _parserOutput.isEmpty
        ? const Center(
            child: Text(
              'Почніть вводити умову в полі ліворуч',
              style: TextStyle(fontSize: 16),
            ),
          )
        : GeometryObjectCanvas(geometryObjects: _parserOutput);

    const padding = EdgeInsets.all(32);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        SizedBox(
          width: size.width / 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: padding,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Умова',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 10,
                  onChanged: _onInputChanged,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: padding,
            child: Container(
              constraints: const BoxConstraints.expand(),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xffefefef),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(1,2),
                    blurRadius: 4,
                  )
                ],
              ),
              child: display,
            ),
          ),
        ),
      ],
    );
  }
}

Iterable<GeometryObject> _assignCoordinates(
  Iterable<GeometryObject> objects, {
  int min = -10,
  int max = 10,
}) sync* {
  final takenCoords = <Coordinates>{};
  final rand = Random(123232);

  Coordinates randomCoords() {
    Coordinates res;

    do {
      final x = rand.nextInt(max + min.abs()) - min.abs();
      final y = rand.nextInt(max + min.abs()) - min.abs();

      res = Coordinates(x, y);
    } while (takenCoords.contains(res));

    return res;
  }

  for (final obj in objects) {
    if (obj is! Point || obj.coordinates != null) {
      if (obj is Point) {
        takenCoords.add(obj.coordinates!);
      }

      yield obj;
      continue;
    }

    yield Point(obj.declaration, randomCoords());
  }
}
