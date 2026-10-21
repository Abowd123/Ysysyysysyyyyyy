import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../effects/particle_layer.dart';
import '../effects/particles.dart';
import 'coloring_controller.dart';
import 'painters.dart';

enum _Gesture { none, draw, transform }

/// The interactive page: tap-to-fill, clipped brush, pinch zoom & pan.
///
/// One finger paints, two fingers zoom/pan. If a second finger lands while a
/// stroke is in progress the stroke is discarded, so zooming never leaves a
/// stray line.
class ColoringCanvas extends StatefulWidget {
  const ColoringCanvas({
    super.key,
    required this.controller,
    this.onEffect,
    this.maxZoom = 6,
  });

  final ColoringController controller;
  final ValueChanged<EffectEvent>? onEffect;
  final double maxZoom;

  @override
  State<ColoringCanvas> createState() => ColoringCanvasState();
}

class _Tick extends ChangeNotifier {
  void ping() => notifyListeners();
}

class ColoringCanvasState extends State<ColoringCanvas>
    with TickerProviderStateMixin {
  final ViewTransform _view = ViewTransform();
  final ArtworkCache _cache = ArtworkCache();
  final ParticleSystem _particles = ParticleSystem();
  final _Tick _animTick = _Tick();
  late ui.Picture _outline;
  late final Ticker _fillTicker = createTicker(_onFillTick);
  Duration _lastFillTick = Duration.zero;

  late final AnimationController _resetAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addListener(_onResetTick);
  double _resetFromZoom = 1;
  Offset _resetFromPan = Offset.zero;

  Size _size = Size.zero;
  double _zoom = 1;
  Offset _pan = Offset.zero;

  // gesture bookkeeping
  int _pointers = 0;
  bool _multiTouch = false;
  Offset? _downLocal;
  _Gesture _gesture = _Gesture.none;
  double _pinchStartZoom = 1;
  Offset _pinchFocalDoc = Offset.zero;
  int _sparkleCounter = 0;

  ColoringController get _c => widget.controller;
  bool get _isTapTool => _c.tool == Tool.fill || _c.tool == Tool.wand;

  double get zoom => _zoom;

  @override
  void initState() {
    super.initState();
    _outline = recordOutline(_c.drawing);
    _c.addListener(_onControllerChanged);
    _c.onEffect = _handleEffect;
  }

  @override
  void didUpdateWidget(ColoringCanvas old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onControllerChanged);
      old.controller.onEffect = null;
      _outline.dispose();
      _outline = recordOutline(_c.drawing);
      _c.addListener(_onControllerChanged);
      _c.onEffect = _handleEffect;
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onControllerChanged);
    if (_c.onEffect == _handleEffect) _c.onEffect = null;
    _fillTicker.dispose();
    _resetAnim.dispose();
    _cache.dispose();
    _outline.dispose();
    _particles.dispose();
    _animTick.dispose();
    _view.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- effects
  void _handleEffect(EffectEvent e) {
    final at = e.at;
    switch (e.kind) {
      case EffectKind.fill:
        if (at != null) {
          _particles.burst(_view.toScreen(at), e.color ?? const Color(0xFFFFFFFF));
        }
      case EffectKind.strokeEnd:
        if (at != null) {
          _particles.burst(_view.toScreen(at), e.color ?? const Color(0xFFFFFFFF),
              count: 6);
        }
      case EffectKind.magicReveal:
        if (at != null) {
          _particles.burst(_view.toScreen(at), e.color ?? const Color(0xFFFFFFFF),
              count: 22);
        }
      case EffectKind.wand:
        if (at != null) {
          final p = _view.toScreen(at);
          _particles.burst(p, const Color(0xFFFFD23F), count: 30);
          _particles.burst(p, const Color(0xFFA66CFF), count: 16);
        }
      default:
        break;
    }
    widget.onEffect?.call(e);
  }

  void _onControllerChanged() {
    if (_c.fills.isNotEmpty && !_fillTicker.isActive) {
      _lastFillTick = Duration.zero;
      _fillTicker.start();
    }
  }

  void _onFillTick(Duration elapsed) {
    final dtMs = (elapsed - _lastFillTick).inMicroseconds / 1000;
    _lastFillTick = elapsed;
    final running = _c.tick(dtMs.clamp(0.0, 50.0));
    _animTick.ping();
    if (!running) _fillTicker.stop();
  }

  // --------------------------------------------------------------- view
  double get _baseScale {
    final d = _c.drawing.size;
    if (_size.isEmpty) return 1;
    return math.min(_size.width / d.width, _size.height / d.height);
  }

  Offset _centered(double k) {
    final d = _c.drawing.size;
    return Offset((_size.width - d.width * k) / 2, (_size.height - d.height * k) / 2);
  }

  Offset _clampPan(Offset pan, double k) {
    final d = _c.drawing.size;
    final mx = math.max(0.0, (d.width * k - _size.width) / 2);
    final my = math.max(0.0, (d.height * k - _size.height) / 2);
    return Offset(pan.dx.clamp(-mx, mx), pan.dy.clamp(-my, my));
  }

  void _applyView() {
    final k = _baseScale * _zoom;
    _pan = _clampPan(_pan, k);
    _view.set(_centered(k) + _pan, k);
  }

  /// Animated return to the full page.
  void resetView() {
    if (_zoom == 1 && _pan == Offset.zero) return;
    _resetFromZoom = _zoom;
    _resetFromPan = _pan;
    _resetAnim.forward(from: 0);
  }

  void _onResetTick() {
    final t = Curves.easeOutCubic.transform(_resetAnim.value);
    _zoom = ui.lerpDouble(_resetFromZoom, 1, t)!;
    _pan = Offset.lerp(_resetFromPan, Offset.zero, t)!;
    _applyView();
  }

  // ----------------------------------------------------------- pointers
  void _onPointerDown(PointerDownEvent e) {
    _pointers++;
    if (_pointers == 1) _downLocal = e.localPosition;
    if (_pointers >= 2) {
      _multiTouch = true;
      _c.cancelStroke(); // second finger: this is a zoom, not a drawing
    }
  }

  void _onPointerUp(PointerEvent e) {
    _pointers = math.max(0, _pointers - 1);
    if (_pointers == 0) {
      _multiTouch = false;
      if (_zoom < 1.03 && _zoom != 1) resetView();
    }
  }

  void _onTapUp(TapUpDetails d) {
    if (_multiTouch) return;
    _c.tapAt(_view.toDoc(d.localPosition));
  }

  void _onScaleStart(ScaleStartDetails d) {
    _resetAnim.stop();
    final wantsTransform = _multiTouch ||
        d.pointerCount >= 2 ||
        (_isTapTool && _zoom > 1); // one-finger pan in fill mode
    if (wantsTransform) {
      _startTransform(d.localFocalPoint);
      return;
    }
    if (_isTapTool) {
      _gesture = _Gesture.none;
      return;
    }
    final start = _view.toDoc(_downLocal ?? d.localFocalPoint);
    if (_c.beginStroke(start)) {
      _gesture = _Gesture.draw;
      _c.extendStroke(_view.toDoc(d.localFocalPoint));
    } else {
      _gesture = _Gesture.none;
    }
  }

  void _startTransform(Offset focal) {
    _gesture = _Gesture.transform;
    _pinchStartZoom = _zoom;
    _pinchFocalDoc = _view.toDoc(focal);
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2 && _gesture != _Gesture.transform) {
      _c.cancelStroke();
      _startTransform(d.localFocalPoint);
      return;
    }
    switch (_gesture) {
      case _Gesture.draw:
        if (_c.extendStroke(_view.toDoc(d.localFocalPoint))) {
          if (++_sparkleCounter % 5 == 0) {
            _particles.sparkle(d.localFocalPoint, _c.live.color);
          }
        }
      case _Gesture.transform:
        _zoom = (_pinchStartZoom * d.scale).clamp(1.0, widget.maxZoom);
        final k = _baseScale * _zoom;
        final t = d.localFocalPoint - _pinchFocalDoc * k;
        _pan = t - _centered(k);
        _applyView();
      case _Gesture.none:
        break;
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_gesture == _Gesture.draw) _c.endStroke();
    _gesture = _Gesture.none;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (size != _size) {
        _size = size;
        _applyView();
      }
      return Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: _onTapUp,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: Stack(children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: ArtworkPainter(
                            controller: _c,
                            view: _view,
                            cache: _cache,
                            animationTick: _animTick,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: LiveStrokePainter(live: _c.live, view: _view),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: OutlinePainter(picture: _outline, view: _view),
                        ),
                      ),
                    ),
                    if (_c.mode == ColoringMode.numbers)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: NumbersPainter(controller: _c, view: _view),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
              Positioned.fill(child: ParticleLayer(system: _particles)),
            ],
          ),
        ),
      );
    });
  }
}
