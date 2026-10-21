import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../core/catalog.dart';
import 'coloring_document.dart';
import 'svg_drawing.dart';

enum Tool { fill, brush, eraser, wand }

/// classic: free choice of colors. magic: swipe to reveal the "real" colors.
/// numbers: color-by-number. free: blank page.
enum ColoringMode { classic, magic, numbers, free }

enum EffectKind {
  fill,
  strokeStart,
  strokeEnd,
  undo,
  redo,
  completed,
  nothing,
  wrong,
  wand,
  magicReveal,
}

/// Something the UI layer should celebrate (particles, sounds, haptics).
class EffectEvent {
  const EffectEvent(this.kind, {this.at, this.color});
  final EffectKind kind;

  /// Document coordinates.
  final Offset? at;
  final Color? color;
}

/// A bucket fill that is still "spreading" from the touch point.
class FillAnimation {
  FillAnimation({
    required this.region,
    required this.origin,
    required this.oldPaint,
    this.delayMs = 0,
  }) : maxRadius = _farthestCorner(region.bounds, origin);

  static const Duration duration = Duration(milliseconds: 380);

  final ColorRegion region;
  final Offset origin;
  final RegionPaint? oldPaint;
  final double maxRadius;
  final double delayMs;
  double elapsedMs = 0;

  double get t =>
      ((elapsedMs - delayMs) / duration.inMilliseconds).clamp(0.0, 1.0);
  bool get done => t >= 1;
  bool get started => elapsedMs >= delayMs;

  /// Ease-out radius of the reveal circle.
  double get radius {
    final x = 1 - t;
    return maxRadius * (1 - x * x * x);
  }

  static double _farthestCorner(Rect r, Offset o) => [
        r.topLeft,
        r.topRight,
        r.bottomLeft,
        r.bottomRight
      ].map((c) => (c - o).distance).reduce(math.max);
}

/// The stroke currently under the finger. Mutable on purpose: appending points
/// must not allocate a new list on every pointer move.
class LiveStroke extends ChangeNotifier {
  ColorRegion? region;
  Color color = const Color(0xFF000000);
  double width = 20;
  BrushStyle style = BrushStyle.normal;
  final List<Offset> points = [];

  bool get active => region != null;

  void start(ColorRegion r, Color c, double w, BrushStyle s, Offset p) {
    region = r;
    color = c;
    width = w;
    style = s;
    points
      ..clear()
      ..add(p);
    notifyListeners();
  }

  /// Returns false when the point was too close to the previous one.
  bool add(Offset p, double minDistance) {
    if (points.isNotEmpty && (p - points.last).distance < minDistance) {
      return false;
    }
    points.add(p);
    notifyListeners();
    return true;
  }

  void reset() {
    region = null;
    points.clear();
    notifyListeners();
  }
}

class ColoringController extends ChangeNotifier {
  ColoringController({
    required this.drawing,
    this.meta,
    this.mode = ColoringMode.classic,
    this.paperColor = const Color(0xFFFFFDF7),
    DocState? initial,
  }) : _state = initial ?? DocState.empty {
    _wasCompleted = isCompleted;
    if (mode == ColoringMode.magic) {
      _tool = Tool.brush;
      _brushSize = 80;
    } else if (mode == ColoringMode.free) {
      _tool = Tool.brush;
    } else if (mode == ColoringMode.numbers && meta != null) {
      _color = meta!.palette.first;
    }
  }

  final SvgDrawing drawing;
  final DrawingMeta? meta;
  final ColoringMode mode;
  final Color paperColor;
  final History _history = History();
  final LiveStroke live = LiveStroke();
  final List<FillAnimation> fills = [];

  /// Coverage (approx. painted area) of magic strokes, per region.
  final Map<String, double> _magicCoverage = {};

  /// Set by the canvas/screen to trigger sounds / particles / haptics.
  ValueChanged<EffectEvent>? onEffect;

  DocState _state;
  DocState get state => _state;

  Tool _tool = Tool.fill;
  Tool get tool => _tool;
  set tool(Tool t) {
    if (_tool == t) return;
    if (mode == ColoringMode.numbers && t != Tool.fill) return;
    _tool = t;
    notifyListeners();
  }

  Color _color = const Color(0xFFFF5A5F);
  Color get color => _color;
  set color(Color c) {
    if (_color == c && _tool != Tool.eraser) return;
    _color = c;
    // Picking a color after erasing returns to the brush; after the wand, to fill.
    if (_tool == Tool.eraser) {
      _tool = Tool.brush;
    } else if (_tool == Tool.wand) {
      _tool = Tool.fill;
    }
    notifyListeners();
  }

  BrushStyle _style = BrushStyle.normal;
  BrushStyle get style => _style;
  set style(BrushStyle s) {
    _style = s;
    if (_tool != Tool.brush) _tool = Tool.brush;
    notifyListeners();
  }

  /// Brush diameter in document units (drawing is 1000 units wide).
  double _brushSize = 28;
  double get brushSize => _brushSize;
  set brushSize(double v) {
    if (_brushSize == v) return;
    _brushSize = v;
    notifyListeners();
  }

  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  Color targetFor(String regionId) {
    if (regionId == SvgDrawing.backgroundId) return meta?.bg ?? paperColor;
    return meta?.regions[regionId]?.target ?? _color;
  }

  int? numberFor(String regionId) => meta?.regions[regionId]?.number;

  /// Number of the currently selected color in color-by-number mode.
  int? get selectedNumber {
    final p = meta?.palette;
    if (p == null) return null;
    final i = p.indexOf(_color);
    return i < 0 ? null : i + 1;
  }

  int get totalRegions => drawing.artRegions.length;
  int get paintedRegions {
    if (mode == ColoringMode.numbers) {
      return drawing.artRegions
          .where((r) => _state[r.id]?.fill == targetFor(r.id))
          .length;
    }
    return _state.paintedCount(drawing.artRegions.map((r) => r.id));
  }

  double get progress => totalRegions == 0 ? 0 : paintedRegions / totalRegions;
  bool get isCompleted =>
      mode != ColoringMode.free &&
      totalRegions > 0 &&
      paintedRegions == totalRegions;
  bool _wasCompleted = false;

  /// True once anything at all is painted (used for free drawings).
  bool get hasContent => _state.regions.values.any((r) => r.isPainted);

  // ------------------------------------------------------------------ fill
  void tapAt(Offset doc) {
    switch (_tool) {
      case Tool.fill:
        fillAt(doc);
      case Tool.wand:
        wandAt(doc);
      case Tool.brush:
      case Tool.eraser:
        // A tap with the brush leaves a round dot.
        if (beginStroke(doc)) endStroke();
    }
  }

  void fillAt(Offset doc) {
    final region = drawing.hitTest(doc);
    if (region == null) return;
    var c = _color;
    if (mode == ColoringMode.numbers) {
      if (region.id == SvgDrawing.backgroundId) {
        c = targetFor(region.id);
      } else if (targetFor(region.id) != _color) {
        _emit(EffectEvent(EffectKind.wrong, at: doc, color: _color));
        return;
      }
    } else if (mode == ColoringMode.magic) {
      c = targetFor(region.id);
    }
    _fillRegion(region, c, doc);
  }

  void _fillRegion(ColorRegion region, Color c, Offset origin,
      {EffectKind effect = EffectKind.fill}) {
    final old = _state[region.id];
    if (old != null && old.fill == c && old.strokes.isEmpty) {
      _emit(EffectEvent(EffectKind.nothing, at: origin, color: c));
      return;
    }
    fills.add(FillAnimation(region: region, origin: origin, oldPaint: old));
    _commit(_state.withFill(region.id, c));
    _emit(EffectEvent(effect, at: origin, color: c));
  }

  /// Magic wand: every untouched region gets its "real" color in a wave that
  /// spreads from the touch point. One undo step.
  void wandAt(Offset doc) {
    final todo = <String, Color>{};
    final anims = <FillAnimation>[];
    for (final r in drawing.regions) {
      final p = _state[r.id];
      if (p != null && p.isPainted) continue;
      if (r.id == SvgDrawing.backgroundId && meta == null) continue;
      final c = targetFor(r.id);
      todo[r.id] = c;
      final center = r.bounds.center;
      anims.add(FillAnimation(
        region: r,
        origin: center,
        oldPaint: p,
        delayMs: (center - doc).distance * 0.9,
      ));
    }
    if (todo.isEmpty) {
      _emit(EffectEvent(EffectKind.nothing, at: doc));
      return;
    }
    fills.addAll(anims);
    _commit(_state.withFills(todo));
    _emit(EffectEvent(EffectKind.wand, at: doc, color: const Color(0xFFFFD23F)));
  }

  // --------------------------------------------------------------- strokes
  Color _strokeColorFor(ColorRegion r) {
    if (_tool == Tool.eraser) return paperColor;
    if (mode == ColoringMode.magic) return targetFor(r.id);
    return _color;
  }

  /// Starts a stroke inside the region under [doc]. Returns false if outside.
  bool beginStroke(Offset doc) {
    if (_tool == Tool.fill || _tool == Tool.wand) return false;
    final region = drawing.hitTest(doc);
    if (region == null) return false;
    final c = _strokeColorFor(region);
    final st = _tool == Tool.eraser || mode == ColoringMode.magic
        ? BrushStyle.normal
        : _style;
    live.start(region, c, _brushSize, st, doc);
    _emit(EffectEvent(EffectKind.strokeStart, at: doc, color: c));
    return true;
  }

  /// Returns true when a point was actually added.
  bool extendStroke(Offset doc) {
    if (!live.active) return false;
    // Finer sampling for thin brushes, coarser for fat ones.
    return live.add(doc, math.max(1.2, _brushSize * 0.08));
  }

  void endStroke() {
    final region = live.region;
    if (region == null) return;
    final pts = List.of(live.points);
    final stroke = BrushStroke(
      regionId: region.id,
      color: live.color,
      width: live.width,
      points: pts,
      style: live.style,
    );
    final last = pts.last;
    final c = live.color;
    live.reset();
    _commit(_state.withStroke(stroke));
    _emit(EffectEvent(EffectKind.strokeEnd, at: last, color: c));
    if (mode == ColoringMode.magic) _checkMagicReveal(region, pts, stroke.width);
  }

  void _checkMagicReveal(ColorRegion region, List<Offset> pts, double width) {
    var len = 0.0;
    for (var i = 1; i < pts.length; i++) {
      len += (pts[i] - pts[i - 1]).distance;
    }
    final covered =
        (_magicCoverage[region.id] ?? 0) + len * width + width * width * 0.8;
    _magicCoverage[region.id] = covered;
    final area = meta?.regions[region.id]?.area ??
        region.bounds.width * region.bounds.height * 0.6;
    final current = _state[region.id];
    if (covered > area * 0.55 &&
        !(current?.fill == targetFor(region.id) && current!.strokes.isEmpty)) {
      // Snap the region to a clean full fill, spreading from the last touch.
      fills.add(FillAnimation(
          region: region, origin: pts.last, oldPaint: current));
      _state = _state.withFill(region.id, targetFor(region.id));
      _afterChange();
      _emit(EffectEvent(EffectKind.magicReveal,
          at: pts.last, color: targetFor(region.id)));
    }
  }

  void cancelStroke() {
    if (live.active) live.reset();
  }

  // ------------------------------------------------------------ undo/redo
  void undo() {
    cancelStroke();
    final prev = _history.undo(_state);
    if (prev == null) return;
    fills.clear();
    _magicCoverage.clear();
    _state = prev;
    _afterChange(silent: true);
    _emit(const EffectEvent(EffectKind.undo));
  }

  void redo() {
    cancelStroke();
    final next = _history.redo(_state);
    if (next == null) return;
    fills.clear();
    _state = next;
    _afterChange(silent: true);
    _emit(const EffectEvent(EffectKind.redo));
  }

  /// Wipes the page (undoable).
  void clearAll() {
    if (_state.regions.isEmpty) return;
    fills.clear();
    _magicCoverage.clear();
    _commit(DocState.empty);
  }

  /// Replaces the state without touching history (used when resuming).
  void restore(DocState s) {
    _history.clear();
    fills.clear();
    _state = s;
    _wasCompleted = isCompleted;
    notifyListeners();
  }

  // --------------------------------------------------------- animations
  /// Advances fill animations. Returns true while any is running.
  bool tick(double dtMs) {
    if (fills.isEmpty) return false;
    for (final f in fills) {
      f.elapsedMs += dtMs;
    }
    fills.removeWhere((f) => f.done);
    return fills.isNotEmpty;
  }

  // ----------------------------------------------------------- internals
  void _commit(DocState next) {
    _history.push(_state);
    _state = next;
    _afterChange();
  }

  void _afterChange({bool silent = false}) {
    final done = isCompleted;
    final justCompleted = done && !_wasCompleted;
    _wasCompleted = done;
    notifyListeners();
    if (justCompleted && !silent) {
      _emit(const EffectEvent(EffectKind.completed));
    }
  }

  void _emit(EffectEvent e) => onEffect?.call(e);

  @override
  void dispose() {
    live.dispose();
    super.dispose();
  }
}
