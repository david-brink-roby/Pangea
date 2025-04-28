import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

/// Mouse button constant for web left-click.
const int kPrimaryMouseButton = 1;

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
    final x = position.dx.clamp(0.0, image.width - 1).toInt();
    final y = position.dy.clamp(0.0, image.height - 1).toInt();
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
    return PixelAwareHitTestBox(image: image, pixelData: pixelData);
  }

  @override
  void updateRenderObject(BuildContext context, PixelAwareHitTestBox renderObject) {}
}

/// Painter to draw a grid overlay for positioning reference.
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color lineColor;
  const GridPainter({ required this.gridSize, required this.lineColor });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) =>
      old.gridSize != gridSize || old.lineColor != lineColor;
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
  bool rotateMode = false;
  Offset? tappedPosition;

  final List<Continent> continents = const [
    Continent('greenland', []),
    Continent('north_america', ['rocks']),
    Continent('south_america', ['glaciers','fossils','rocks']),
    Continent('africa', ['glaciers','fossils','rocks']),
    Continent('eurasia', ['rocks']),
    Continent('india', ['glaciers','fossils']),
    Continent('arabia', []),
    Continent('madagascar', ['glaciers','fossils']),
    Continent('australia', ['glaciers','fossils']),
    Continent('antartica', ['glaciers','fossils']),
  ];

  final Map<String,Offset> positions = const {
    'greenland':     Offset(0.497, 0.263),
    'north_america': Offset(0.245, 0.250),
    'south_america': Offset(0.339, 0.427),
    'africa':        Offset(0.516, 0.361),
    'eurasia':       Offset(0.530, 0.150),
    'india':         Offset(0.731, 0.393),
    'arabia':        Offset(0.678, 0.381),
    'madagascar':    Offset(0.697, 0.542),
    'australia':     Offset(0.768, 0.534),
    'antartica':     Offset(0.507, 0.655),
  };

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (evt) {
        setState(() {
          rotateMode = evt.isKeyPressed(LogicalKeyboardKey.keyR);
        });
      },
      child: LayoutBuilder(
        builder: (ctx, box) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (d) => setState(() => tappedPosition = d.localPosition),
            child: Stack(children: [
              if (tappedPosition != null) ...[
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
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    color: Colors.black54,
                    child: Builder(builder: (_){
                      final w = box.maxWidth, h = box.maxHeight;
                      final dx = tappedPosition!.dx, dy = tappedPosition!.dy;
                      return Text(
                        'Tap: x=${dx.toStringAsFixed(1)}, '
                        'y=${dy.toStringAsFixed(1)}   '
                        'Rel: dx=${(dx/w).toStringAsFixed(3)}, '
                        'dy=${(dy/h).toStringAsFixed(3)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    }),
                  ),
                ),
              ],
              CustomPaint(
                size: Size(box.maxWidth, box.maxHeight),
                painter: const GridPainter(
                  gridSize: 50,
                  lineColor: Color.fromRGBO(128,128,128,0.5),
                ),
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
                  rotateMode: rotateMode,
                ),
              Positioned(
                top: 10, left: 10,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white70,
                    child: Column(mainAxisSize: MainAxisSize.min, children:[
                      CheckboxListTile(
                        title: const Text('Fossils'),
                        value: showFossils,
                        onChanged: (v)=> setState((){
                          showFossils = v!;
                          if (v) showGlaciers = showRocks = false;
                        }),
                      ),
                      CheckboxListTile(
                        title: const Text('Glaciers'),
                        value: showGlaciers,
                        onChanged: (v)=> setState((){
                          showGlaciers = v!;
                          if (v) showFossils = showRocks = false;
                        }),
                      ),
                      CheckboxListTile(
                        title: const Text('Rock Outcrops'),
                        value: showRocks,
                        onChanged: (v)=> setState((){
                          showRocks = v!;
                          if (v) showFossils = showGlaciers = false;
                        }),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class InteractiveContinent extends StatefulWidget {
  final String name;
  final List<String> overlays;
  final Offset initialPosition;
  final bool showFossils, showGlaciers, showRocks, rotateMode;

  const InteractiveContinent({
    Key? key,
    required this.name,
    required this.overlays,
    required this.initialPosition,
    required this.showFossils,
    required this.showGlaciers,
    required this.showRocks,
    required this.rotateMode,
  }) : super(key: key);

  @override
  _InteractiveContinentState createState() => _InteractiveContinentState();
}

class _InteractiveContinentState extends State<InteractiveContinent> {
  late Offset position;
  double rotation = 0.0;
  ui.Image? _image;
  ByteData? _pixels;
  bool _dragging = false, _rotating = false;
  late Offset _startPtr, _startPos;
  late double _startRot;

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
    _image = frame.image;
    _pixels = await _image!.toByteData(format: ui.ImageByteFormat.rawRgba);
    setState(() {});
  }

  bool _opaqueHit(Offset local) {
    if (_image == null || _pixels == null) return true;
    final c = Offset(_image!.width/2, _image!.height/2);
    final m = Matrix4.identity()
      ..translate(c.dx, c.dy)
      ..rotateZ(-rotation)
      ..translate(-c.dx, -c.dy);
    final t = MatrixUtils.transformPoint(m, local);
    final x = t.dx.round(), y = t.dy.round();
    if (x < 0 || y < 0 || x >= _image!.width || y >= _image!.height) return false;
    final idx = (y * _image!.width + x) * 4;
    return _pixels!.getUint8(idx + 3) > 16;
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null || _pixels == null) return const SizedBox.shrink();

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: PixelAwareContinent(
        image: _image!,
        pixelData: _pixels!,
        child: MouseRegion(
          cursor: widget.rotateMode
            ? SystemMouseCursors.alias
            : SystemMouseCursors.move,
          child: Listener(
            onPointerDown: (e) {
              final box = context.findRenderObject() as RenderBox;
              final loc = box.globalToLocal(e.position);
              if (!_opaqueHit(loc)) return;

              if (e.buttons == kPrimaryMouseButton) {
                if (widget.rotateMode) {
                  _rotating = true;
                  _startPtr = e.position;
                  _startRot = rotation;
                } else {
                  _dragging = true;
                  _startPtr = e.position;
                  _startPos = position;
                }
              }
            },
            onPointerMove: (e) {
              if (_dragging) {
                setState(() => position = _startPos + (e.position - _startPtr));
              } else if (_rotating) {
                setState(() =>
                  rotation = _startRot + (e.position.dx - _startPtr.dx) * 0.01
                );
              }
            },
            onPointerUp: (_) {
              _dragging = _rotating = false;
            },
            child: Transform.rotate(
              angle: rotation,
              alignment: Alignment.center,
              child: Stack(children: [
                Image.asset('assets/${widget.name}.png'),
                if (widget.showGlaciers && widget.overlays.contains('glaciers'))
                  Image.asset('assets/${widget.name}_glaciers.png'),
                if (widget.showFossils && widget.overlays.contains('fossils'))
                  Image.asset('assets/${widget.name}_fossils.png'),
                if (widget.showRocks && widget.overlays.contains('rocks'))
                  Image.asset('assets/${widget.name}_rocks.png'),
                Positioned(
                  top: -18, left: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      'Off: (${position.dx.toStringAsFixed(1)}, '
                      '${position.dy.toStringAsFixed(1)})',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
