import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../core/catalog.dart';
import 'coloring_document.dart';
import 'painters.dart';
import 'svg_drawing.dart';

/// "Bring the drawing to life": the child's own colors, animated part by part
/// (puppet style) using the `anim` specs shipped with each drawing.
class LivingPainter extends CustomPainter {
  LivingPainter({
    required this.drawing,
    required this.state,
    required this.meta,
    required this.time,
    this.paper = const Color(0xFFFFFDF7),
    this.ink = const Color(0xFF2B1B12),
    this.showBackground = true,
  }) : super(repaint: time);

  final SvgDrawing drawing;
  final DocState state;
  final DrawingMeta? meta;

  /// Seconds since the drawing came alive.
  final ValueListenable<double> time;
  final Color paper;
  final Color ink;
  final bool showBackground;

  /// Background decorations keep their own gentle motion and don't hop.
  static const _ambient = {
    'scene', 'sun', 'cloud', 'stars', 'moon', 'smoke', 'bubbles', 'notes',
    'puff', 'weed', 'speed',
  };

  static final Paint _edge = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final k = math.min(size.width / drawing.size.width,
        size.height / drawing.size.height);
    canvas.save();
    canvas.translate((size.width - drawing.size.width * k) / 2,
        (size.height - drawing.size.height * k) / 2);
    canvas.scale(k);
    canvas.clipRect(drawing.rect);

    // Entrance: anticipation, jump, landing squash; then gentle breathing.
    final hop = _entrance(t);
    final cb = _characterBounds();
    final center = Offset(cb.center.dx, cb.bottom);
    final grounded = cb.bottom > 820 && meta?.world != 'space';

    // Pass 1: scenery (ground, sky decorations) with its own lines.
    // Pass 2: the character on top, so scenery lines never cross it.
    for (final pass in [true, false]) {
      for (final r in drawing.regions) {
        final p = state[r.id];
        if (r.id == SvgDrawing.backgroundId) {
          if (!pass || !showBackground) continue;
          canvas.drawRect(drawing.rect, Paint()..color = paper);
          if (p != null && p.isPainted) paintRegion(canvas, r, p);
          continue;
        }
        if (_ambient.contains(r.part) != pass) continue;
        canvas.save();
        if (!pass) _applyHop(canvas, hop, center);
        _applyPart(canvas, r.part, t, 0);
        canvas.drawPath(r.rawPath, Paint()..color = paper);
        if (p != null && p.isPainted) paintRegion(canvas, r, p, clip: r.rawPath);
        if (r.strokeWhenAlive) {
          canvas.drawPath(r.rawPath, _edge..color = ink);
        }
        canvas.restore();
      }
      for (final o in drawing.outline) {
        if (o.isEdge || _ambient.contains(o.part) != pass) continue;
        canvas.save();
        if (!pass) _applyHop(canvas, hop, center);
        _applyPart(canvas, o.part, t, 0);
        canvas.drawPath(o.path, o.paint);
        canvas.restore();
      }
      if (pass && grounded) {
        // Contact shadow: shrinks and fades while the character is in the air.
        final w = cb.width * 0.42 * (1 - 0.45 * hop.$4) * hop.$1;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, cb.bottom - 4), width: w * 2, height: w * 0.26),
          Paint()..color = const Color(0xFF000000).withValues(alpha: 0.16 * (1 - 0.6 * hop.$4)),
        );
      }
    }
    canvas.restore();
  }

  Rect? _charBounds;
  Rect _characterBounds() {
    if (_charBounds != null) return _charBounds!;
    Rect? r;
    for (final reg in drawing.regions) {
      if (reg.id == SvgDrawing.backgroundId || _ambient.contains(reg.part)) continue;
      final b = reg.rawPath.getBounds();
      r = r == null ? b : r.expandToInclude(b);
    }
    return _charBounds = r ?? const Rect.fromLTRB(300, 300, 700, 900);
  }

  /// (scaleX, scaleY, dy, lift 0..1). Classic animation principles:
  /// anticipation -> stretch in the air -> squash on landing -> settle,
  /// followed by slow breathing so the character never freezes.
  (double, double, double, double) _entrance(double t) {
    if (t < 0.16) {
      final k = math.sin(math.pi / 2 * t / 0.16);
      return (1 + 0.08 * k, 1 - 0.12 * k, 0, 0);
    }
    if (t < 0.56) {
      final j = math.sin(math.pi * (t - 0.16) / 0.40);
      return (1 - 0.05 * j, 1 + 0.09 * j, -95 * j, j);
    }
    final v = t - 0.56;
    final wob = v < 1.6 ? math.sin(math.pi * 3 * v / 0.84) * math.exp(-4 * v) : 0.0;
    final br = math.sin(2 * math.pi * 0.45 * t);
    return (1 + 0.10 * wob - 0.008 * br, 1 - 0.10 * wob + 0.012 * br, 0, 0);
  }

  void _applyHop(Canvas c, (double, double, double, double) hop, Offset base) {
    if (hop.$1 == 1 && hop.$2 == 1 && hop.$3 == 0) return;
    c.translate(base.dx, base.dy + hop.$3);
    c.scale(hop.$1, hop.$2);
    c.translate(-base.dx, -base.dy);
  }

  void _applyPart(Canvas c, String part, double t, int depth) {
    final spec = meta?.anim[part];
    if (spec == null || depth > 3) return;
    final follow = spec.follow;
    if (follow != null && follow != part) _applyPart(c, follow, t, depth + 1);
    final pivot = spec.pivot ?? drawing.partBounds(part).center;
    // Tails trail behind the body (follow-through) unless a phase is given.
    final phase = spec.phase == 0 && part.startsWith('tail') ? -0.9 : spec.phase;
    final w = 2 * math.pi * spec.speed * t + phase;
    final a = spec.amp;
    // Two harmonics instead of a pure sine: reads organic, not robotic.
    final organic = (math.sin(w) + 0.22 * math.sin(2 * w + 0.8)) / 1.1;
    void rotateDeg(double deg) {
      c.translate(pivot.dx, pivot.dy);
      c.rotate(deg * math.pi / 180);
      c.translate(-pivot.dx, -pivot.dy);
    }

    void scaleAt(double sx, double sy) {
      c.translate(pivot.dx, pivot.dy);
      c.scale(sx, sy);
      c.translate(-pivot.dx, -pivot.dy);
    }

    switch (spec.type) {
      case 'tilt':
      case 'swing':
      case 'wave':
      case 'nod':
      case 'sway_top':
      case 'orbit':
      case 'roll':
        rotateDeg(a * organic);
      case 'flap':
        // Faster down-stroke than up-stroke, like real wings.
        rotateDeg(a * math.sin(w) * (0.75 + 0.25 * math.sin(w)));
      case 'spin':
        rotateDeg(360 * spec.speed * t * a.sign);
      case 'blink':
        // Every ~3.4 s, a 160 ms blink.
        final cycle = (t + spec.phase) % 3.4;
        final b = cycle > 3.24 ? math.sin(math.pi * (cycle - 3.24) / 0.16) : 0.0;
        scaleAt(1, 1 - 0.9 * b);
      case 'bounce':
      case 'bounce_big':
        c.translate(0, -a * math.sin(w).abs());
      case 'fly':
      case 'float':
        c.translate(0, a * math.sin(w));
      case 'swim':
        c.translate(a * 0.7 * math.cos(w * 0.5), a * math.sin(w));
      case 'drift':
      case 'sway':
        c.translate(a * math.sin(w), 0);
      case 'shake':
        c.translate(a * math.sin(w * 1.7), a * 0.5 * math.cos(w * 2.3));
      case 'buzz':
        c.translate(a * math.sin(w), a * 0.5 * math.sin(2 * w));
      case 'rise':
        final f = (t * spec.speed) % 1.0;
        c.translate(math.sin(w * 2) * 6, -f * a * 2);
      case 'pulse':
      case 'flicker':
      case 'twinkle':
      case 'breathe':
        final s = 1 + a * math.sin(spec.type == 'flicker' ? w * 1.7 : w);
        scaleAt(s, s);
      case 'flutter':
        scaleAt(1, math.max(0.15, math.cos(w).abs()));
      case 'flap_x':
        scaleAt(1 - a * (0.5 + 0.5 * math.sin(w)), 1);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(LivingPainter old) =>
      old.state != state || old.drawing != drawing;
}
