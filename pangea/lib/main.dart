import 'package:flutter/material.dart';

void main() => runApp(PangeaApp());

class PangeaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangea',
      home: Scaffold(
        appBar: AppBar(title: Text('Pangea')),
        body: PangeaMap(),
      ),
    );
  }
}

class PangeaMap extends StatefulWidget {
  @override
  _PangeaMapState createState() => _PangeaMapState();
}

class _PangeaMapState extends State<PangeaMap> {
  // Toggle states
  bool showFossils = true;
  bool showGlaciers = true;
  bool showRocks = true;

  // List of 10 continent file keys
  final continents = [
    'antartica', 'australia', 'africa', 'eurasia', 'india',
    'madagascar', 'north_america', 'south_america', 'arabia', 'greenland',
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Render each continent with layering
        ...continents.map((name) {
          return InteractiveContinent(
            baseAsset: 'assets/$name.png',
            fossilsAsset: 'assets/${name}_fossils.png',
            glaciersAsset: 'assets/${name}_glaciers.png',
            rocksAsset: 'assets/${name}_rocks.png',
            showFossils: showFossils,
            showGlaciers: showGlaciers,
            showRocks: showRocks,
          );
        }).toList(),

        // Layer toggles
        Positioned(
          top: 10, left: 10,
          child: Container(
            padding: EdgeInsets.all(8), color: Colors.white70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('Fossils'),
                  value: showFossils,
                  onChanged: (v) => setState(() => showFossils = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Text('Glaciers'),
                  value: showGlaciers,
                  onChanged: (v) => setState(() => showGlaciers = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: Text('Rock Outcrops'),
                  value: showRocks,
                  onChanged: (v) => setState(() => showRocks = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class InteractiveContinent extends StatefulWidget {
  final String baseAsset;
  final String fossilsAsset;
  final String glaciersAsset;
  final String rocksAsset;
  final bool showFossils;
  final bool showGlaciers;
  final bool showRocks;

  InteractiveContinent({
    required this.baseAsset,
    required this.fossilsAsset,
    required this.glaciersAsset,
    required this.rocksAsset,
    required this.showFossils,
    required this.showGlaciers,
    required this.showRocks,
  });

  @override
  _InteractiveContinentState createState() => _InteractiveContinentState();
}

class _InteractiveContinentState extends State<InteractiveContinent> {
  Offset position = Offset(100, 100);
  double rotation = 0.0;
  late Offset _startFocalPoint;
  late Offset _startPosition;
  late double _startRotation;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx, top: position.dy,
      child: GestureDetector(
        onScaleStart: (details) {
          _startFocalPoint = details.focalPoint;
          _startPosition = position;
          _startRotation = rotation;
        },
        onScaleUpdate: (details) {
          setState(() {
            position = _startPosition + (details.focalPoint - _startFocalPoint);
            rotation = _startRotation + details.rotation;
          });
        },
        child: Transform.rotate(
          angle: rotation,
          alignment: Alignment.center,
          child: Stack(
            children: [
              Image.asset(widget.baseAsset),
              if (widget.showGlaciers) Image.asset(widget.glaciersAsset),
              if (widget.showFossils) Image.asset(widget.fossilsAsset),
              if (widget.showRocks) Image.asset(widget.rocksAsset),
            ],
          ),
        ),
      ),
    );
  }
}