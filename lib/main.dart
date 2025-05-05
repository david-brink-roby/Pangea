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
const double designHeight = 500;

 /// How big each continent should be, *before* we fit the whole canvas to the screen.
  double continentBaseScale = .8; // try 0.8, 1.2, etc.

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
  bool showFossils     = true;
  bool showGlaciers    = false;
  bool showRocks       = false;
  bool rotateMode      = false;
  bool showBottomMenu  = false;
  int  resetCounter    = 0;
  Offset? tapped;

  // Absolute positions provided by user
  static const Map<String, Offset> absoluteStart = {
    'greenland':     Offset(411.8, -48.0),
    'north_america': Offset(64.9, -84.3),
    'south_america': Offset(173.6, 138.1),
    'africa':        Offset(382.8, 38.4),
    'eurasia':       Offset(366.8, -230.5),
    'india':         Offset(647.8, 85.9),
    'arabia':        Offset(591.2, 91.8),
    'madagascar':    Offset(624.4, 238.6),
    'australia':     Offset(784.7, 205.9),
    'antartica':     Offset(451.6, 291.4),
  };

  // Convert to normalized coords [0..1]
  late final Map<String, Offset> normalizedStart = absoluteStart.map(
    (key, abs) => MapEntry(
      key,
      Offset(abs.dx / designWidth, abs.dy / designHeight),
    ),
  );
  final List<Continent> continents = const [
    Continent('madagascar', ['glaciers', 'fossils']),
    Continent('greenland', []),
    Continent('north_america', ['rocks']),
    Continent('south_america', ['glaciers', 'fossils', 'rocks']),
    Continent('africa', ['glaciers', 'fossils', 'rocks']),
    Continent('eurasia', ['rocks']),
    Continent('india', ['glaciers', 'fossils']),
    Continent('arabia', []),
    Continent('australia', ['glaciers', 'fossils']),
    Continent('antartica', ['glaciers', 'fossils']),
  ];

  final Map<String, Offset> currentPos = {};

  void _resetPositions() {
    setState(() {
      normalizedStart.forEach((key, norm) {
        currentPos[key] = Offset(
          norm.dx * designWidth,
          norm.dy * designHeight,
        );
      });
      resetCounter++;
    });
  }

  @override
  void initState() {
    super.initState();
    normalizedStart.forEach((key, value) {
      currentPos[key] = Offset(
        value.dx * designWidth,
        value.dy * designHeight,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reconstruct Pangea'),
          content: const Text(
            '• To move a continent: left-click and drag it.\n'
            '• To rotate: enter Rotate Mode (hit “R” or tap the rotate button), then drag horizontally.\n'
            '• To rotate on mobile: either tap the rotate button or use two fingers to pinch and rotate.\n'
            '• Toggle rotation mode: press the rotate icon at top-right.\n'
            '• Layer & legend: use the bottom-right menu to pick a layer and see its key.\n'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
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

        // ensure Madagascar is drawn first (in back):
        final ordered = [
          continents.firstWhere((c) => c.name == 'madagascar'),
          ...continents.where((c) => c.name != 'madagascar'),
        ];

        return Stack(
          children: [
            // ─── the map canvas ──────────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: (details) {
                  final r     = ctx.findRenderObject() as RenderBox;
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
                          // background + grid
                          Positioned.fill(
                            child: Image.asset(
                              'assets/background.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_,__,___)=>
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

                          // continents, Madagascar first
                          for (final c in ordered)
                            InteractiveContinent(
                              key: ValueKey(c.name),
                              name: c.name,
                              overlays: c.overlays,
                              initialPosition: currentPos[c.name]!,
                              resetCounter: resetCounter,
                              showFossils:  showFossils,
                              showGlaciers: showGlaciers,
                              showRocks:    showRocks,
                              rotateMode:   rotateMode,
                              onPositionChanged: _onPositionChanged,
                              continentScale: continentBaseScale,
                            ),

                          // Dump‐coords button (for dev)
                          Positioned(
                            left: 8, top: 8,
                            child: ElevatedButton(
                              onPressed: _dumpCoords,
                              child: const Text('Dump coords'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── top-right: Reset + Rotate ───────────
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Reset Positions?'),
                          content: const Text(
                            'Are you sure you want to reset all continent positions?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) _resetPositions();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      rotateMode
                        ? Icons.rotate_right_outlined
                        : Icons.rotate_right,
                      color: rotateMode ? Colors.blue : Colors.black87,
                    ),
                    tooltip: 'Toggle rotate mode (R)',
                    onPressed: () =>
                      setState(() => rotateMode = !rotateMode),
                  ),
                ],
              ),
            ),

            // ─── bottom-right: hamburger for Layer+Key menu ───
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.black87,
                onPressed: () => setState(() => showBottomMenu = !showBottomMenu),
              ),
            ),

            if (showBottomMenu)
              Positioned(
                bottom: 56,
                right: 8,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  color: Colors.white70,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // the key image
                      SizedBox(
                        height: 80,
                        child: _buildKey(),
                      ),

                      const SizedBox(height: 8),

                      // three layer‐select buttons
                      Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black87),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => setState(() {
                              showFossils  = true;
                              showGlaciers = showRocks = false;
                            }),
                            child: Image.asset(
                              'assets/button_fossils.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text('Fossils'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black87),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => setState(() {
                              showGlaciers = true;
                              showFossils  = showRocks = false;
                            }),
                            child: Image.asset(
                              'assets/button_glaciers.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text('Glaciers'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.black87),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => setState(() {
                              showRocks    = true;
                              showFossils  = showGlaciers = false;
                            }),
                            child: Image.asset(
                              'assets/button_rocks.png',
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Text('Rocks'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  /// Returns the correct key‐PNG for the active layer.
  Widget _buildKey() {
    String asset;
    if (showGlaciers)  asset = 'assets/key_glaciers.png';
    else if (showRocks) asset = 'assets/key_rocks.png';
    else               asset = 'assets/key_fossils.png';

    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
        const Center(child: Text('Key not found')),
    );
  }
}


class InteractiveContinent extends StatefulWidget {
  final String name;
  final List<String> overlays;
  final Offset initialPosition;
  final int resetCounter;
  final bool showFossils, showGlaciers, showRocks, rotateMode;
  final void Function(String, Offset) onPositionChanged;
  final double continentScale;

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
    required this.resetCounter, 
    required this.continentScale, 
    
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

  @override
  void didUpdateWidget(covariant InteractiveContinent old) {
    super.didUpdateWidget(old);
    // only reset on a true “reset” event, not on every drag
    if (old.resetCounter != widget.resetCounter) {
      setState(() {
        position = widget.initialPosition;
        rotation = 0.0;                     // reset rotation
      });
    }
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
        child: MouseRegion(
      // if rotateMode is on, show the “alias” (rotate) cursor;
      // otherwise show the standard move cursor
      cursor: widget.rotateMode
        ? SystemMouseCursors.alias
        : SystemMouseCursors.move,
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
          child: Transform.scale(
            scale: widget.continentScale,               // ← apply base scale here
            alignment: Alignment.center,
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
            )
          ),
        ),
      ),
      ),
    );
  }
}
