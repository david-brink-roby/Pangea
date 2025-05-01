import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

/// Mouse button constant for web left-click.
const int kPrimaryMouseButton = 1;

/// “Design” canvas size your map was authored at.
const double designWidth = 1200;
const double designHeight = 650;

void main() => runApp(const PangeaApp());

class PangeaApp extends StatelessWidget {
  const PangeaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pangea',
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        body: const SafeArea(child: PangeaMap()),
      ),
    );
  }
}

class Continent {
  final String name;
  final List<String> overlays;
  const Continent(this.name, this.overlays);
}

/// Only hit on opaque pixels.
class PixelAwareHitTestBox extends RenderProxyBox {
  final ui.Image image;
  final ByteData pixelData;
  PixelAwareHitTestBox({
    required this.image,
    required this.pixelData,
    RenderBox? child,
  }) : super(child);

  @override
  bool hitTestSelf(Offset pos) {
    final x = pos.dx.clamp(0.0, image.width - 1).toInt();
    final y = pos.dy.clamp(0.0, image.height - 1).toInt();
    final idx = (y * image.width + x) * 4;
    return pixelData.getUint8(idx + 3) > 16;
  }

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position }) {
    if (!hitTestSelf(position)) return false;
    return super.hitTest(result, position: position);
  }
}

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
  RenderObject createRenderObject(BuildContext _) =>
      PixelAwareHitTestBox(image: image, pixelData: pixelData);

  @override
  void updateRenderObject(BuildContext _, RenderObject renderObject) {}
}

class GridPainter extends CustomPainter {
  final double gridSize;
  final Color lineColor;
  const GridPainter({ required this.gridSize, required this.lineColor });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = lineColor..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) =>
      old.gridSize != gridSize || old.lineColor != lineColor;
}

class PangeaMap extends StatefulWidget {
  const PangeaMap({Key? key}) : super(key: key);

  @override
  _PangeaMapState createState() => _PangeaMapState();
}

class _PangeaMapState extends State<PangeaMap> {
  bool showFossils  = true;
  bool showGlaciers = false;
  bool showRocks    = false;
  bool rotateMode   = false;
  bool showMenu     = false;
  bool showKey      = false;
  Offset? tapped;

  // Absolute positions provided by user
  static const Map<String, Offset> absoluteStart = {
    'greenland':     Offset(385.1, -6.7),
    'north_america': Offset(68.9, -35.6),
    'south_america': Offset(192.9, 234.1),
    'africa':        Offset(414.8, 130.4),
    'eurasia':       Offset(432.1, -169.2),
    'india':         Offset(717.1, 161.9),
    'arabia':        Offset(643.9, 165.8),
    'madagascar':    Offset(661.7, 337.9),
    'australia':     Offset(768.7, 328.6),
    'antartica':     Offset(442.9, 419.4),
  };

  // Convert to normalized coords [0..1]
  late final Map<String, Offset> normalizedStart = absoluteStart.map(
    (key, abs) => MapEntry(
      key,
      Offset(abs.dx / designWidth, abs.dy / designHeight),
    ),
  );
  final List<Continent> continents = const [
    Continent('greenland', []),
    Continent('north_america', ['rocks']),
    Continent('south_america', ['glaciers', 'fossils', 'rocks']),
    Continent('africa', ['glaciers', 'fossils', 'rocks']),
    Continent('eurasia', ['rocks']),
    Continent('india', ['glaciers', 'fossils']),
    Continent('arabia', []),
    Continent('madagascar', ['glaciers', 'fossils']),
    Continent('australia', ['glaciers', 'fossils']),
    Continent('antartica', ['glaciers', 'fossils']),
  ];

  final Map<String, Offset> currentPos = {};

  @override
  void initState() {
    super.initState();
    normalizedStart.forEach((key, value) {
      currentPos[key] = Offset(value.dx * designWidth, value.dy * designHeight);
    });
  }

  void _onPositionChanged(String name, Offset pos) {
    setState(() {
      currentPos[name] = pos;
    });
  }

  void _dumpCoords() {
    debugPrint('// dump at ${DateTime.now()}');
    for (var entry in currentPos.entries) {
      final p = entry.value;
      debugPrint(
        "'${entry.key}': Offset(${p.dx.toStringAsFixed(1)}, ${p.dy.toStringAsFixed(1)}),"
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (evt) => setState(() {
        rotateMode = evt.isKeyPressed(LogicalKeyboardKey.keyR);
      }),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final availW = constraints.maxWidth;
        final scale  = availW / designWidth;

        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final r  = ctx.findRenderObject() as RenderBox;
                final local = r.globalToLocal(details.globalPosition);
                setState(() => tapped = local / scale);
              },
              child: Container(
                width: availW,
                height: designHeight * scale,
                color: Colors.transparent,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: designWidth,
                    height: designHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/background.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) =>
                                Container(color: Colors.grey[300]),
                          ),
                        ),
                        CustomPaint(
                          size: Size(designWidth, designHeight),
                          painter: const GridPainter(
                            gridSize: 50,
                            lineColor: Color.fromRGBO(128,128,128,0.5),
                          ),
                        ),
                        if (tapped != null) ...[
                          Positioned(
                            left: tapped!.dx - 10,
                            top: tapped!.dy,
                            child: Container(width:20, height:1, color:Colors.red),
                          ),
                          Positioned(
                            left: tapped!.dx,
                            top: tapped!.dy - 10,
                            child: Container(width:1, height:20, color:Colors.red),
                          ),
                        ],
                        for (final c in continents)
                          InteractiveContinent(
                            key: ValueKey(c.name),
                            name: c.name,
                            overlays: c.overlays,
                            initialPosition: currentPos[c.name]!,
                            showFossils: showFossils,
                            showGlaciers: showGlaciers,
                            showRocks: showRocks,
                            rotateMode: rotateMode,
                            onPositionChanged: _onPositionChanged,
                          ),

                        // Layers button top-left
                        Positioned(
                          left: 8, top: 8,
                          child: IconButton(
                            icon: const Icon(Icons.menu),
                            color: Colors.black87,
                            onPressed: () => setState(() => showMenu = !showMenu),
                          ),
                        ),
                        if (showMenu)
                          Positioned(
                            left: 8, top: 56,
                            child: Container(
                              width: 200,
                              padding: const EdgeInsets.all(8),
                              color: Colors.white70,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                     children: [
                                      const Text('Rotate', style: TextStyle(fontSize:14)),
                                      const SizedBox(width:6),
                                      Image.asset('assets/rotate_hint.png', width:20, height:20),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          rotateMode
                                            ? Icons.rotate_right_outlined
                                            : Icons.rotate_right,
                                        ),
                                        onPressed: () => setState(() => rotateMode = !rotateMode),
                                      ),
                                    ],
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Fossils'),
                                    value: showFossils,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (v) => setState(() {
                                      showFossils = v!;
                                      if (v) showGlaciers = showRocks = false;
                                    }),
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Glaciers'),
                                    value: showGlaciers,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (v) => setState(() {
                                      showGlaciers = v!;
                                      if (v) showFossils = showRocks = false;
                                    }),
                                  ),
                                  CheckboxListTile(
                                    title: const Text('Rocks'),
                                    value: showRocks,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: (v) => setState(() {
                                      showRocks = v!;
                                      if (v) showFossils = showGlaciers = false;
                                    }),
                                  ),
                                  const Divider(),
                                  ElevatedButton(
                                    onPressed: _dumpCoords,
                                    child: const Text('Dump coords'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Key (legend) button bottom-right
                        Positioned(
                          right: 8, bottom: 8,
                          child: IconButton(
                            icon: const Icon(Icons.menu),
                            color: Colors.black87,
                            onPressed: () => setState(() => showKey = !showKey),
                          ),
                        ),
                        if (showKey)
                          Positioned(
                            right: 8, bottom: 56,
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(4),
                              color: Colors.white70,
                              child: () {
                                String asset;
                                if (showFossils)      asset = 'assets/key_fossils.png';
                                else if (showGlaciers) asset = 'assets/key_glaciers.png';
                                else if (showRocks)    asset = 'assets/key_rocks.png';
                                else                   asset = '';
                                return asset.isNotEmpty
                                  ? Image.asset(asset, fit: BoxFit.contain)
                                  : const SizedBox.shrink();
                              }(),
                            ),
                          ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class InteractiveContinent extends StatefulWidget {
  final String name;
  final List<String> overlays;
  final Offset initialPosition;
  final bool showFossils, showGlaciers, showRocks, rotateMode;
  final void Function(String, Offset) onPositionChanged;

  const InteractiveContinent({
    Key? key,
    required this.name,
    required this.overlays,
    required this.initialPosition,
    required this.showFossils,
    required this.showGlaciers,
    required this.showRocks,
    required this.rotateMode,
    required this.onPositionChanged,
  }) : super(key: key);

  @override
  _InteractiveContinentState createState() => _InteractiveContinentState();
}

class _InteractiveContinentState extends State<InteractiveContinent> {
  late Offset position;
  double rotation = 0.0;
  ui.Image? _image;
  ByteData? _pixels;
  late Rect _opaqueBounds;
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
    final data  = await rootBundle.load('assets/${widget.name}.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _image  = frame.image;
    _pixels = await _image!.toByteData(format: ui.ImageByteFormat.rawRgba);

    final w = _image!.width, h = _image!.height;
    int minX = w, minY = h, maxX = 0, maxY = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = (y * w + x) * 4;
        if (_pixels!.getUint8(idx + 3) > 16) {
          minX = min(minX, x);
          minY = min(minY, y);
          maxX = max(maxX, x);
          maxY = max(maxY, y);
        }
      }
    }
    _opaqueBounds = Rect.fromLTRB(
      minX.toDouble(), minY.toDouble(),
      maxX.toDouble(), maxY.toDouble(),
    );
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
      left: position.dx, top: position.dy,
      child: PixelAwareContinent(
        image: _image!,
        pixelData: _pixels!,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onScaleStart: (details) {
            final box   = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(details.focalPoint);
            if (!_opaqueHit(local)) return;
            if (details.pointerCount > 1 || widget.rotateMode) {
              _rotating = true;
              _startRot = rotation;
            } else {
              _dragging = true;
              _startPos = position;
              _startPtr = details.focalPoint;
            }
          },
          onScaleUpdate: (details) {
            if (_dragging) {
              final rawdx = _startPos.dx + (details.focalPoint.dx - _startPtr.dx);
              final rawdy = _startPos.dy + (details.focalPoint.dy - _startPtr.dy);

              final c  = Offset(_image!.width/2, _image!.height/2);
              final m  = Matrix4.identity()
                ..translate(c.dx, c.dy)
                ..rotateZ(rotation)
                ..translate(-c.dx, -c.dy);
              final corners = [
                _opaqueBounds.topLeft,
                _opaqueBounds.topRight,
                _opaqueBounds.bottomRight,
                _opaqueBounds.bottomLeft,
              ].map((p) => MatrixUtils.transformPoint(m, p)).toList();
              final minX = corners.map((o) => o.dx).reduce(min);
              final maxX = corners.map((o) => o.dx).reduce(max);
              final minY = corners.map((o) => o.dy).reduce(min);
              final maxY = corners.map((o) => o.dy).reduce(max);

              // allow half the opaque bounds out of view
              final halfW = (maxX - minX) / 2;
              final halfH = (maxY - minY) / 2;
              final lowerX = (0 - minX) - halfW;
              final upperX = (designWidth - maxX) + halfW;
              final lowerY = (0 - minY) - halfH;
              final upperY = (designHeight - maxY) + halfH;

              final clampedX = rawdx.clamp(lowerX, upperX);
              final clampedY = rawdy.clamp(lowerY, upperY);

              setState(() {
                position = Offset(clampedX, clampedY);
                widget.onPositionChanged(widget.name, position);
              });
            } else if (_rotating) {
              final delta = details.pointerCount > 1
                ? details.rotation
                : (details.focalPoint.dx - _startPtr.dx) * 0.01;
              setState(() {
                rotation = _startRot + delta;
              });
            }
          },
          onScaleEnd: (_) {
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
                Positioned(
                  top: -18, left: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      'Off: (${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
