import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

/// Mouse button constants for web onPointerDown checks.
const int kPrimaryMouseButton = 1;
const int kSecondaryMouseButton = 2;

/// A RenderBox that only responds to pointer events on opaque pixels.
class PixelAwareHitTestBox extends RenderProxyBox {
  final ui.Image image;
  final ByteData pixelData;

  PixelAwareHitTestBox({
    required this.image,
    required this.pixelData,
    RenderBox? child,
  }) : super(child);

  @override
  bool hitTestSelf(Offset position) {
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final x = position.dx.clamp(0.0, width - 1).toInt();
    final y = position.dy.clamp(0.0, height - 1).toInt();
    final idx = (y * image.width + x) * 4;
    final alpha = pixelData.getUint8(idx + 3);
    return alpha > 16;
  }

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position }) {
    if (!hitTestSelf(position)) return false;
    return super.hitTest(result, position: position);
  }
}

/// Wraps a widget subtree with PixelAwareHitTestBox for precise hits.
class PixelAwareContinent extends SingleChildRenderObjectWidget {
  final ui.Image image;
  final ByteData pixelData;

  const PixelAwareContinent({
    Key? key,
    required this.image,
    required this.pixelData,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PixelAwareHitTestBox(
      image: image,
      pixelData: pixelData,
    );
  }

  @override
  void updateRenderObject(BuildContext context, PixelAwareHitTestBox renderObject) {}
}

/// Painter to draw a grid overlay for positioning reference.
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color lineColor;

  GridPainter({ required this.gridSize, required this.lineColor });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) {
    return old.gridSize != gridSize || old.lineColor != lineColor;
  }
}

void main() => runApp(const PangeaApp());

class PangeaApp extends StatelessWidget {
  const PangeaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangea',
      home: Scaffold(
        appBar: AppBar(title: const Text('Pangea')),
        body: const PangeaMap(),
      ),
    );
  }
}

class Continent {
  final String name;
  final List<String> overlays;
  const Continent(this.name, this.overlays);
}

class PangeaMap extends StatefulWidget {
  const PangeaMap({Key? key}) : super(key: key);

  @override
  _PangeaMapState createState() => _PangeaMapState();
}

class _PangeaMapState extends State<PangeaMap> {
  bool showFossils = true;
  bool showGlaciers = false;
  bool showRocks = false;
  Offset? tappedPosition;

  final List<Continent> continents = const [
    Continent('greenland', []),
    Continent('north_america', ['rocks']),
    Continent('south_america', ['glaciers', 'fossils', 'rocks']),
    Continent('africa', ['fossils', 'rocks']),
    Continent('eurasia', ['rocks']),
    Continent('india', ['glaciers', 'fossils']),
    Continent('arabia', []),
    Continent('madagascar', ['glaciers', 'fossils']),
    Continent('australia', ['glaciers', 'fossils']),
    Continent('antartica', ['glaciers', 'fossils']),
  ];

  final Map<String, Offset> positions = const {
    'greenland': Offset(0.497, 0.263),
    'north_america': Offset(0.245, 0.250),
    'south_america': Offset(0.339, 0.427),
    'africa': Offset(0.516, 0.361),
    'eurasia': Offset(0.530, 0.150),
    'india': Offset(0.731, 0.393),
    'arabia': Offset(0.678, 0.381),
    'madagascar': Offset(0.697, 0.542),
    'australia': Offset(0.768, 0.534),
    'antartica': Offset(0.507, 0.655),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) => setState(() => tappedPosition = details.localPosition),
          child: Stack(
            children: [
              if (tappedPosition != null) ...[
                // Crosshair at tapped point
                Positioned(
                  left: tappedPosition!.dx - 10,
                  top: tappedPosition!.dy,
                  child: Container(width: 20, height: 1, color: Colors.red),
                ),
                Positioned(
                  left: tappedPosition!.dx,
                  top: tappedPosition!.dy - 10,
                  child: Container(width: 1, height: 20, color: Colors.red),
                ),
                // Display pixel and relative coordinates
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.black54,
                    child: Builder(
                      builder: (context) {
                        final width = box.maxWidth;
                        final height = box.maxHeight;
                        final relX = tappedPosition!.dx / width;
                        final relY = tappedPosition!.dy / height;
                        return Text(
                          'Tap: x=${tappedPosition!.dx.toStringAsFixed(1)}, y=${tappedPosition!.dy.toStringAsFixed(1)}  '
                          'Rel: dx=${relX.toStringAsFixed(3)}, dy=${relY.toStringAsFixed(3)}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
              ],
              CustomPaint(
                size: Size(box.maxWidth, box.maxHeight),
                painter: GridPainter(gridSize: 50, lineColor: Color.fromRGBO(128, 128, 128, 0.5)),
              ),
              for (final c in continents)
                InteractiveContinent(
                  key: ValueKey(c.name),
                  name: c.name,
                  overlays: c.overlays,
                  initialPosition: Offset(
                    positions[c.name]!.dx * box.maxWidth,
                    positions[c.name]!.dy * box.maxHeight,
                  ),
                  showFossils: showFossils,
                  showGlaciers: showGlaciers,
                  showRocks: showRocks,
                ),
              Positioned(
                top: 10,
                left: 10,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white70,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckboxListTile(
                          title: const Text('Fossils'),
                          value: showFossils,
                          onChanged: (v) => setState(() {
                            showFossils = v!;
                            if (v) { showGlaciers = false; showRocks = false; }
                          }),
                        ),
                        CheckboxListTile(
                          title: const Text('Glaciers'),
                          value: showGlaciers,
                          onChanged: (v) => setState(() {
                            showGlaciers = v!;
                            if (v) { showFossils = false; showRocks = false; }
                          }),
                        ),
                        CheckboxListTile(
                          title: const Text('Rock Outcrops'),
                          value: showRocks,
                          onChanged: (v) => setState(() {
                            showRocks = v!;
                            if (v) { showFossils = false; showGlaciers = false; }
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class InteractiveContinent extends StatefulWidget {
  final String name;
  final List<String> overlays;
  final Offset initialPosition;
  final bool showFossils;
  final bool showGlaciers;
  final bool showRocks;

  const InteractiveContinent({
    Key? key,
    required this.name,
    required this.overlays,
    required this.initialPosition,
    required this.showFossils,
    required this.showGlaciers,
    required this.showRocks,
  }) : super(key: key);

  @override
  _InteractiveContinentState createState() => _InteractiveContinentState();
}

class _InteractiveContinentState extends State<InteractiveContinent> {
  late Offset position;
  double rotation = 0.0;
  ui.Image? _decodedImage;
  ByteData? _imagePixels;
  bool _dragging = false;
  bool _rotating = false;
  late Offset _startPointer;
  late Offset _startPosition;
  late double _startRotation;

  @override
  void initState() {
    super.initState();
    position = widget.initialPosition;
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await rootBundle.load('assets/${widget.name}.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _decodedImage = frame.image;
    _imagePixels = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  }

  bool _isOpaquePixel(Offset local) {
    if (_decodedImage == null || _imagePixels == null) return true;
    final center = Offset(_decodedImage!.width / 2, _decodedImage!.height / 2);
    final mat = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..rotateZ(-rotation)
      ..translate(-center.dx, -center.dy);
    final transformed = MatrixUtils.transformPoint(mat, local);
    final x = transformed.dx.round();
    final y = transformed.dy.round();
    if (x < 0 || y < 0 || x >= _decodedImage!.width || y >= _decodedImage!.height) return false;
    final idx = (y * _decodedImage!.width + x) * 4;
    return _imagePixels!.getUint8(idx + 3) > 10;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: (_decodedImage != null && _imagePixels != null)
          ? PixelAwareContinent(
              image: _decodedImage!,
              pixelData: _imagePixels!,
              child: Listener(
                onPointerDown: (e) {
                  // Log absolute and normalized offsets
                  final screenSize = MediaQuery.of(context).size;
                  final relX = position.dx / screenSize.width;
                  final relY = position.dy / screenSize.height;
                  debugPrint(
                    'Image "${widget.name}" offset: '
                    '(${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)}) px  '
                    'Rel: (${relX.toStringAsFixed(3)}, ${relY.toStringAsFixed(3)})'
                  );

                  final box = context.findRenderObject() as RenderBox;
                  final loc = box.globalToLocal(e.position);
                  if (!_isOpaquePixel(loc)) return;
                  if (e.buttons == kPrimaryMouseButton) {
                    _dragging = true;
                    _startPointer = e.position;
                    _startPosition = position;
                  } else if (e.buttons == kSecondaryMouseButton) {
                    _rotating = true;
                    _startPointer = e.position;
                    _startRotation = rotation;
                  }
                },
                onPointerMove: (e) {
                  if (_dragging) {
                    setState(() => position = _startPosition + (e.position - _startPointer));
                    debugPrint(
                      'Continent "${widget.name}" moved to: '
                      '(${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})'
                    );
                  } else if (_rotating) {
                    setState(() =>
                      rotation = _startRotation + (e.position.dx - _startPointer.dx) * 0.01
                    );
                  }
                },
                onPointerUp: (_) {
                  _dragging = false;
                  _rotating = false;
                },
                child: Transform.rotate(
                  angle: rotation,
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      Image.asset('assets/${widget.name}.png'),
                      if (widget.showGlaciers && widget.overlays.contains('glaciers'))
                        Image.asset('assets/${widget.name}_glaciers.png'),
                      if (widget.showFossils && widget.overlays.contains('fossils'))
                        Image.asset('assets/${widget.name}_fossils.png'),
                      if (widget.showRocks && widget.overlays.contains('rocks'))
                        Image.asset('assets/${widget.name}_rocks.png'),
                      // Live offset label
                      Positioned(
                        top: -18,
                        left: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(2),
                          child: Text(
                            'Offset: (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
