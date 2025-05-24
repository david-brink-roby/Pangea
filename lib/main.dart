import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

/// Mouse button constant for web left-click.
const int kPrimaryMouseButton = 1;

/// “Design” canvas size your map was authored at.
const double designWidth = 4320;
const double designHeight = 2200;

/// How big each continent should be, *before* we fit the whole canvas to the screen.
double continentBaseScale = .8;

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

/// Only hit on opaque pixels, remapped for scaled rendering.
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
    final RenderBox childBox = child as RenderBox;
    final Size paintedSize = childBox.size;
    final double sx = image.width / paintedSize.width;
    final double sy = image.height / paintedSize.height;
    final int x = (pos.dx * sx).clamp(0.0, image.width - 1).toInt();
    final int y = (pos.dy * sy).clamp(0.0, image.height - 1).toInt();
    final int idx = (y * image.width + x) * 4;
    final int alpha = pixelData.getUint8(idx + 3);
    return alpha > 16;
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
  bool showFossils     = false;
  bool showGlaciers    = false;
  bool showRocks       = false;
  bool showContinents  = true;
  bool rotateMode      = false;
  bool showBottomMenu  = false;
  int  resetCounter    = 0;
  Offset? tapped;
  String? legendLayer;

  static const Map<String, Offset> absoluteStart = {
    'greenland': Offset(1531.8, 99.4),
    'north_america': Offset(547.6, 115.7),
    'south_america': Offset(1136.2, 822.7),
    'africa': Offset(1932.8, 564.3),
    'eurasia': Offset(2021.5, 98.6),
    'india': Offset(2785.7, 632.5),
    'madagascar': Offset(2535.8, 1130.6),
    'australia': Offset(3221.4, 1027.9),
    'antartica': Offset(274.4, 1110.7),
  };

  late final Map<String, Offset> normalizedStart = absoluteStart.map(
    (key, abs) => MapEntry(
      key,
      Offset(abs.dx / designWidth, abs.dy / designHeight),
    ),
  );

  final List<Continent> continents = const [
    Continent('madagascar', ['glaciers', 'fossils']),
    Continent('greenland', ['rocks', 'fossils']),
    Continent('south_america', ['glaciers', 'fossils']),
    Continent('north_america', ['rocks', 'fossils']),
    Continent('africa', ['glaciers', 'fossils', 'rocks']),
    Continent('eurasia', ['rocks', 'fossils']),
    Continent('india', ['glaciers', 'fossils']),
    Continent('australia', ['glaciers', 'fossils']),
    Continent('antartica', ['glaciers', 'fossils']),
  ];

  final Map<String, Offset> currentPos = {};

  // GlobalKey to access the RenderBox of the SizedBox representing the design canvas
  final GlobalKey _mapCanvasKey = GlobalKey();

  // State for legend key position and opacity for animation
  Offset _legendKeyPosition = Offset.zero; // Initialized to zero
  double _legendKeyOpacity = 0.0;
  Size _currentScreenSize = Size.zero; // To accurately place the fixed key


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
      // Show initial dialog
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

      // Initialize legend key position after the first frame is rendered
      // and context.size is available.
      if (mounted) { // Ensure widget is still in tree
        final initialScreenSize = MediaQuery.of(context).size;
        _currentScreenSize = initialScreenSize; // Set initial screen size
        _updateLegendKeyPosition(); // Calculate and set initial legend position
      }
    });
  }

  @override
  void didUpdateWidget(covariant PangeaMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This is called when the widget's configuration changes.
    // We get the new constraints from the LayoutBuilder in the build method.
    // If the screen size has changed (which causes LayoutBuilder to rebuild),
    // update the legend key's position.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final newScreenSize = (context.findRenderObject() as RenderBox).size;
        if (_currentScreenSize != newScreenSize) {
          _currentScreenSize = newScreenSize;
          _updateLegendKeyPosition();
        }
      }
    });
  }


  void _onPositionChanged(String name, Offset pos) {
    setState(() { currentPos[name] = pos; });
  }

  void _dumpCoords() {
    debugPrint('// dump at ${DateTime.now()}');
    currentPos.forEach((key, p) {
      debugPrint("'$key': Offset(${p.dx.toStringAsFixed(1)}, ${p.dy.toStringAsFixed(1)}),");
    });
  }

  // Function to update the legend key's position (now fixed)
  void _updateLegendKeyPosition() {
    // Key dimensions
    const double keyWidth = 300;
    const double keyHeight = 300;
    const double screenMargin = 16.0; // Margin from screen edges
    const double gapToButtons = 30.0; // New: Gap between legend and buttons row

    if (_currentScreenSize == Size.zero) {
      return;
    }

    // Calculate fixed position for the key in the bottom-right corner.
    // It should be 30 pixels above the row of buttons which starts at bottom: 8
    final double buttonsBottomOffset = 8.0; // This is the 'bottom' value of the button row
    final double fixedKeyLeft = _currentScreenSize.width - keyWidth - screenMargin;
    final double fixedKeyTop = _currentScreenSize.height - keyHeight - buttonsBottomOffset - gapToButtons;


    // Only call setState if the position actually needs to change to avoid unnecessary rebuilds
    if (_legendKeyPosition.dx != fixedKeyLeft || _legendKeyPosition.dy != fixedKeyTop) {
      setState(() {
        _legendKeyPosition = Offset(fixedKeyLeft, fixedKeyTop);
      });
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
        // LayoutBuilder rebuilds when constraints change.
        // We use didUpdateWidget to react to constraint changes for _currentScreenSize.
        // No direct setState or _updateLegendKeyPosition call in build here.

        final availW = constraints.maxWidth;
        final scale  = availW / designWidth; // The scale factor to convert design coords to screen pixels

        final ordered = [
          continents.firstWhere((c) => c.name == 'madagascar'),
          ...continents.where((c) => c.name != 'madagascar'),
        ];

        return Stack(children: [
          // ─── Main canvas ───────────────────────────
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                // Dim the legend key when tapping anywhere else on the map
                setState(() {
                  _legendKeyOpacity = 0.0;
                  legendLayer = null; // Also clear the active layer
                });

                // Use the GlobalKey to get the RenderBox of the map canvas
                final RenderBox? mapBox = _mapCanvasKey.currentContext?.findRenderObject() as RenderBox?;
                if (mapBox == null) return; // Defensive check
                final local = mapBox.globalToLocal(details.globalPosition); // Convert to design coords
                setState(() => tapped = local); // Tap position in design coords
              },
              child: Container(
                width:  availW,
                height: designHeight * scale,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    key: _mapCanvasKey, // Assign the GlobalKey here
                    width:  designWidth,
                    height: designHeight,
                    child: Stack(children: [ // This is the parent Stack for continents and background
                      // background + grid
                      Positioned.fill(
                        child: Image.asset(
                          'assets/background.png', // Corrected asset path
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
                      // continents
                      for (final c in ordered)
                        Positioned( // Positioned MUST be a direct child of Stack
                          left: currentPos[c.name]!.dx, // Use currentPos from PangeaMapState
                          top:  currentPos[c.name]!.dy, // Use currentPos from PangeaMapState
                          child: RepaintBoundary( // RepaintBoundary wraps the InteractiveContinent
                            child: InteractiveContinent(
                              key: ValueKey(c.name),
                              name: c.name,
                              overlays: c.overlays,
                              initialPosition: currentPos[c.name]!,
                              resetCounter: resetCounter,
                              showFossils: showFossils && !showContinents,
                              showGlaciers: showGlaciers && !showContinents,
                              showRocks: showRocks && !showContinents,
                              rotateMode: rotateMode,
                              onPositionChanged: _onPositionChanged,
                              continentScale: continentBaseScale,
                              currentScreenScale: scale, // Pass the current screen scale
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          // ─── Top-right: Reset + Rotate ─────────────
          Positioned(
            top: 8, right: 8,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Reset Positions?'),
                      content: const Text(
                        'Are you sure you want to reset all positions?'
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
                  if (ok == true) _resetPositions();
                },
              ),
              IconButton(
                icon: Icon(
                  rotateMode ? Icons.rotate_right_outlined : Icons.rotate_right,
                  color: rotateMode ? Colors.blue : Colors.black87,
                ),
                tooltip: 'Toggle Rotate Mode (R)',
                onPressed: () => setState(() => rotateMode = !rotateMode),
              ),
            ]),
          ),

          // ─── Bottom-right: layer buttons ───────────
          Positioned(
            bottom: 8, right: 8,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _layerButton(
                asset: 'assets/button_fossils.png',
                label: 'Fossils',
                active: showFossils,
                onTap: () {
                  setState(() {
                    legendLayer = (legendLayer == 'fossils') ? null : 'fossils';
                    showFossils = true;
                    showGlaciers = showRocks = showContinents = false;
                    _legendKeyOpacity = legendLayer != null ? 1.0 : 0.0; // Control opacity here
                  });
                },
              ),
              const SizedBox(width: 4),
              _layerButton(
                asset: 'assets/button_glaciers.png',
                label: 'Glaciers',
                active: showGlaciers,
                onTap: () {
                  setState(() {
                    legendLayer = (legendLayer == 'glaciers') ? null : 'glaciers';
                    showGlaciers = true;
                    showFossils = showRocks = showContinents = false;
                    _legendKeyOpacity = legendLayer != null ? 1.0 : 0.0;
                  });
                },
              ),
              const SizedBox(width: 4),
              _layerButton(
                asset: 'assets/button_rocks.png',
                label: 'Rocks',
                active: showRocks,
                onTap: () {
                  setState(() {
                    legendLayer = (legendLayer == 'rocks') ? null : 'rocks';
                    showRocks = true;
                    showFossils = showGlaciers = showContinents = false;
                    _legendKeyOpacity = legendLayer != null ? 1.0 : 0.0;
                  });
                },
              ),
              const SizedBox(width: 4),
              _layerButton(
                asset: 'assets/button_continents.png',
                label: 'Continents',
                active: showContinents,
                onTap: () {
                  setState(() {
                    legendLayer = (legendLayer == 'continents') ? null : 'continents';
                    showContinents = true;
                    showFossils = showGlaciers = showRocks = false;
                    _legendKeyOpacity = legendLayer != null ? 1.0 : 0.0;
                  });
                },
              ),
            ]),
          ),

          // ─── Bottom-left: multiline text watermark ───
          Positioned(
            bottom: 8,
            left: 8,
            child: IgnorePointer( // Allow interaction with elements behind it
              child: Opacity(
                opacity: 1,  // Adjust opacity if desired
                child: Text(
                  'Modified from the U.S. Geological Survey\nCreated by Skyler Clagg\nArtwork by Gray Cramer & David Brink-Roby',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.3,        // line spacing
                  ),
                ),
              ),
            ),
          ),

          // ─── Legend key (fixed position with IgnorePointer) ───────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
            left: _legendKeyPosition.dx,
            top: _legendKeyPosition.dy,
            // Only ignore pointer events if opacity is low (effectively hidden)
            child: IgnorePointer(
              ignoring: _legendKeyOpacity < 0.05, // Use a small threshold like 0.05
              child: AnimatedOpacity(
                opacity: _legendKeyOpacity,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
                // Only display the Image.asset if legendLayer is not null to avoid errors
                child: legendLayer != null
                    ? Image.asset(
                        'assets/key_$legendLayer.png',
                        width: 300, // Fixed width for the key image
                        height: 300, // Fixed height for the key image
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : const SizedBox.shrink(), // Display nothing if legendLayer is null
              ),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _layerButton({
    required String asset,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        // Removed `side` to remove the outline
        // side: BorderSide(color: active ? Colors.blue : Colors.black87),

        padding: EdgeInsets.zero, // Set padding to zero
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Keep rounded corners

        minimumSize: const Size(48, 48), // Enforce a minimum size for the button
      ),
      onPressed: onTap,
      child: Image.asset(
        asset,
        width: 75, // Control the size of the image, which indirectly controls the button size
        height: 48, // Control the size of the image, which indirectly controls the button size
        fit: BoxFit.cover, // Ensures image fills the button space, may crop
        errorBuilder: (_, __, ___) => Text(label),
      ),
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
  final double currentScreenScale;

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
    required this.currentScreenScale,
  }) : super(key:key);

  @override
  _InteractiveContinentState createState() => _InteractiveContinentState();
}

class _InteractiveContinentState extends State<InteractiveContinent> {
  late Offset _currentPosition;
  double rotation = 0.0;
  ui.Image? _image;
  ByteData? _pixels;
  late Rect _opaqueBounds;
  bool _dragging = false, _rotating = false;
  late Offset _startPtrGlobal;
  late Offset _dragStartContinentPositionDesign;
  late double _startRot;


  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant InteractiveContinent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetCounter != widget.resetCounter) {
      setState(() {
        _currentPosition = widget.initialPosition;
        rotation = 0.0;
      });
    }
    else if (!_dragging && !_rotating && oldWidget.initialPosition != widget.initialPosition) {
       _currentPosition = widget.initialPosition;
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
        if (_pixels!.getUint8(idx + 3) > 0) {
          minX = min(minX, x);
          minY = min(minY, y);
          maxX = max(maxX, x);
          maxY = max(maxY, y);
        }
      }
    }
    _opaqueBounds = Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX.toDouble(), maxY.toDouble());
    setState(() {});
  }

  bool _opaqueHit(Offset local) {
    if (_image == null || _pixels == null) return false;
    final c = Offset(_image!.width/2, _image!.height/2);
    final m = Matrix4.identity()..translate(c.dx, c.dy)..rotateZ(-rotation)..translate(-c.dx, -c.dy);
    final t = MatrixUtils.transformPoint(m, local);
    final x = t.dx.round(), y = t.dy.round();
    if (x < 0 || y < 0 || x >= _image!.width || y >= _image!.height) return false;
    final idx = (y * _image!.width + x) * 4;
    return _pixels!.getUint8(idx + 3) > 0;
  }

  void _onScaleStart(ScaleStartDetails details) {
    final RenderBox continentRenderBox = context.findRenderObject() as RenderBox;
    final Offset localHitPoint = continentRenderBox.globalToLocal(details.focalPoint);

    if (!_opaqueHit(localHitPoint)) return;

    if (details.pointerCount > 1 || widget.rotateMode) {
      _rotating = true;
      _startRot = rotation;
      _startPtrGlobal = details.focalPoint;
    } else {
      _dragging = true;
      _dragStartContinentPositionDesign = _currentPosition;
      _startPtrGlobal = details.focalPoint;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_dragging) {
      final dxGlobal = details.focalPoint.dx - _startPtrGlobal.dx;
      final dyGlobal = details.focalPoint.dy - _startPtrGlobal.dy;

      final dxDesign = dxGlobal / widget.currentScreenScale;
      final dyDesign = dyGlobal / widget.currentScreenScale;

      final newDx = _dragStartContinentPositionDesign.dx + dxDesign;
      final newDy = _dragStartContinentPositionDesign.dy + dyDesign;

      setState(() {
        _currentPosition = Offset(newDx, newDy);
        widget.onPositionChanged(widget.name, _currentPosition);
      });
    } else if (_rotating) {
      final delta = details.pointerCount > 1
          ? details.rotation
          : (details.focalPoint.dx - _startPtrGlobal.dx) * 0.01;
      setState(() => rotation = _startRot + delta);
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_dragging) {
      if (_image != null) {
        final double imageRenderedWidth = _image!.width.toDouble();
        final double imageRenderedHeight = _image!.height.toDouble();

        final c = Offset(imageRenderedWidth / 2, imageRenderedHeight / 2);

        final m = Matrix4.identity()
          ..translate(c.dx, c.dy)
          ..rotateZ(rotation)
          ..translate(-c.dx, -c.dx);

        final corners = [
          _opaqueBounds.topLeft,
          _opaqueBounds.topRight,
          _opaqueBounds.bottomRight,
          _opaqueBounds.bottomLeft,
        ].map((p) {
          final transformedPoint = MatrixUtils.transformPoint(m, p);
          return Offset(
            transformedPoint.dx * widget.continentScale,
            transformedPoint.dy * widget.continentScale,
          );
        }).toList();

        final minXRotatedScaled = corners.map((o) => o.dx).reduce(min);
        final maxXRotatedScaled = corners.map((o) => o.dx).reduce(max);
        final minYRotatedScaled = corners.map((o) => o.dy).reduce(min);
        final maxYRotatedScaled = corners.map((o) => o.dy).reduce(max);

        final rotatedContentWidth = maxXRotatedScaled - minXRotatedScaled;
        final rotatedContentHeight = maxYRotatedScaled - minYRotatedScaled;

        // Adjust clamping limits to allow 50% of the opaque pixels to go off-canvas
        final clampedLowerX = -(0.5 * rotatedContentWidth) - minXRotatedScaled;
        final clampedUpperX = designWidth + (0.5 * rotatedContentWidth) - maxXRotatedScaled;
        final clampedLowerY = -(0.5 * rotatedContentHeight) - minYRotatedScaled;
        final clampedUpperY = designHeight + (0.5 * rotatedContentHeight) - maxYRotatedScaled;

        debugPrint('--- Clamping Diagnostics for ${widget.name} ---');
        debugPrint('Original Position: $_currentPosition');
        debugPrint('Rotation: $rotation');
        debugPrint('Opaque Bounds (raw px): $_opaqueBounds');
        debugPrint('Rotated & Scaled Bounding Box (design units): X=$minXRotatedScaled - $maxXRotatedScaled, Y=$minYRotatedScaled - $maxYRotatedScaled');
        debugPrint('Rotated Content Size (design units): W=$rotatedContentWidth, H=$rotatedContentHeight');
        debugPrint('Design Canvas: Width=$designWidth, Height=$designHeight');
        debugPrint('Calculated Clamping Limits: lowerX=$clampedLowerX, upperX=$clampedUpperX, lowerY=$clampedLowerY, upperY=$clampedUpperY');

        final clampedX = _currentPosition.dx.clamp(clampedLowerX, clampedUpperX);
        final clampedY = _currentPosition.dy.clamp(clampedLowerY, clampedUpperY);

        debugPrint('Clamped Position: Offset($clampedX, $clampedY)');

        setState(() {
          _currentPosition = Offset(clampedX, clampedY);
          widget.onPositionChanged(widget.name, _currentPosition);
        });
      }
    }
    _dragging = _rotating = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null || _pixels == null) {
      return const SizedBox.shrink();
    }

    final double logicalW = _image!.width * widget.continentScale;
    final double logicalH = _image!.height * widget.continentScale;

    return PixelAwareContinent(
      image: _image!,
      pixelData: _pixels!,
      child: MouseRegion(
        cursor: widget.rotateMode
            ? SystemMouseCursors.alias
            : SystemMouseCursors.move,
        child: Transform.rotate(
          angle: rotation,
          alignment: Alignment.center,
          transformHitTests: true,
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: SizedBox(
              width:  logicalW,
              height: logicalH,
              child: Stack(fit:StackFit.expand, children:[
                Image.asset(
                  'assets/${widget.name}.png',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) =>
                    Center(child: Text('Error loading ${widget.name}.png')),
                ),
                if (widget.showGlaciers && widget.overlays.contains('glaciers'))
                  Image.asset(
                    'assets/${widget.name}_glaciers.png',
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                  ),
                if (widget.showFossils && widget.overlays.contains('fossils'))
                  Image.asset(
                    'assets/${widget.name}_fossils.png',
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                  ),
                if (widget.showRocks && widget.overlays.contains('rocks'))
                  Image.asset(
                    'assets/${widget.name}_rocks.png',
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}