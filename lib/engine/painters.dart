import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'brushes.dart';
import 'coloring_controller.dart';
import 'coloring_document.dart';
import 'svg_drawing.dart';

export 'brushes.dart' show buildStrokePath, strokePaint, drawStroke;

/// Maps document space (e.g. 1000x1000) to widget space: screen = t + doc * s.
class ViewTransform extends ChangeNotifier {
  Offset _translation = Offset.zero;
  double _scale = 1;

  Offset get translation => _translation;
  double get scale => _scale;

  void set(Offset translation, double scale) {
    if (translation == _translation && scale == _scale) return;
    _translation = translation;
    _scale = scale;
    notifyListeners();
  }

  Offset toDoc(Offset screen) => (screen - _translation) / _scale;
  Offset toScreen(Offset doc) => _translation + doc * _scale;

  void apply(Canvas canvas) {
    canvas.translate(_translation.dx, _translation.dy);
    canvas.scale(_scale);
  }
}

/// Soft 2.5D volume on filled character parts: a highlight from the top-left
/// and a gentle shade bottom-right (same look as the art previews).
const _volumeColors = [Color(0x61FFFFFF), Color(0x00FFFFFF), Color(0x29000000)];
const _volumeStops = [0.0, 0.55, 1.0];

void _paintVolume(Canvas canvas, Rect b) {
  final r = b.longestSide * 0.85;
  final center = Offset(b.left + b.width * 0.3, b.top + b.height * 0.25);
  canvas.drawRect(
    b.inflate(2),
    Paint()
      ..shader = ui.Gradient.radial(center, r, _volumeColors, _volumeStops),
  );
}

/// Paints fill + strokes of one region, clipped to [clip] (visible or raw).
void paintRegion(Canvas canvas, ColorRegion region, RegionPaint paint,
    {Path? clip}) {
  canvas.save();
  canvas.clipPath(clip ?? region.visiblePath);
  final b = clip?.getBounds() ?? region.bounds;
  if (paint.fill != null) {
    canvas.drawRect(b.inflate(2), Paint()..color = paint.fill!);
    // Scenery (ground, sea, road) stays flat; characters get volume.
    if (region.strokeWhenAlive && region.id != SvgDrawing.backgroundId) {
      _paintVolume(canvas, region.rawPath.getBounds());
    }
  }
  for (final s in paint.strokes) {
    drawStroke(canvas, s.points, s.color, s.width, s.style);
  }
  canvas.restore();
}

/// Paper + every painted region (no line art), in document space.
void paintArtwork(Canvas c, SvgDrawing drawing, DocState state, Color paper) {
  c.drawRect(drawing.rect, Paint()..color = paper);
  for (final r in drawing.regions) {
    final p = state[r.id];
    if (p != null && p.isPainted) paintRegion(c, r, p);
  }
}

/// Records the committed artwork into a [ui.Picture] once per state change, so
/// zooming, panning and animations only replay a cached display list.
class ArtworkCache {
  DocState? _state;
  ui.Picture? _picture;

  ui.Picture pictureFor(SvgDrawing drawing, DocState state, Color paper) {
    if (_picture != null && identical(_state, state)) return _picture!;
    _picture?.dispose();
    final rec = ui.PictureRecorder();
    paintArtwork(Canvas(rec, drawing.rect), drawing, state, paper);
    _picture = rec.endRecording();
    _state = state;
    return _picture!;
  }

  void dispose() => _picture?.dispose();
}

class ArtworkPainter extends CustomPainter {
  ArtworkPainter({
    required this.controller,
    required this.view,
    required this.cache,
    required Listenable animationTick,
  }) : super(repaint: Listenable.merge([controller, view, animationTick]));

  final ColoringController controller;
  final ViewTransform view;
  final ArtworkCache cache;

  @override
  void paint(Canvas canvas, Size size) {
    final drawing = controller.drawing;
    canvas.save();
    view.apply(canvas);
    canvas.clipRect(drawing.rect);
    canvas.drawPicture(
        cache.pictureFor(drawing, controller.state, controller.paperColor));

    // Spreading fills: cover the region with its *old* paint, then reveal the
    // new paint inside the growing circle. Only clips, no path boolean ops,
    // so even a 25-region magic-wand wave stays cheap.
    for (final f in controller.fills) {
      final region = f.region;
      canvas.save();
      canvas.clipPath(region.visiblePath);
      canvas.drawRect(region.bounds.inflate(2), Paint()..color = controller.paperColor);
      final old = f.oldPaint;
      if (old != null && old.isPainted) paintRegion(canvas, region, old);
      if (f.started && f.radius > 0.5) {
        final current = controller.state[region.id];
        if (current != null && current.isPainted) {
          canvas.save();
          canvas.clipPath(Path()
            ..addOval(Rect.fromCircle(center: f.origin, radius: f.radius)));
          paintRegion(canvas, region, current);
          canvas.restore();
        }
        // A soft bright rim on the wave front.
        final rim = (1 - f.t) * 0.55;
        if (rim > 0.01) {
          canvas.drawCircle(
            f.origin,
            f.radius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 14
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
              ..color = const Color(0xFFFFFFFF).withValues(alpha: rim),
          );
        }
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArtworkPainter old) =>
      old.controller != controller || old.view != view;
}

/// Only the stroke under the finger: repaints on every pointer move without
/// touching the rest of the artwork.
class LiveStrokePainter extends CustomPainter {
  LiveStrokePainter({required this.live, required this.view})
      : super(repaint: Listenable.merge([live, view]));

  final LiveStroke live;
  final ViewTransform view;

  @override
  void paint(Canvas canvas, Size size) {
    final region = live.region;
    if (region == null || live.points.isEmpty) return;
    canvas.save();
    view.apply(canvas);
    canvas.clipPath(region.visiblePath);
    drawStroke(canvas, live.points, live.color, live.width, live.style);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LiveStrokePainter old) =>
      old.live != live || old.view != view;
}

/// Records the line art once per drawing.
ui.Picture recordOutline(SvgDrawing drawing) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec, drawing.rect);
  for (final o in drawing.outline) {
    if (o.aliveOnly) continue;
    c.drawPath(o.path, o.paint);
  }
  return rec.endRecording();
}

/// Line art, always on top so children can never cover the black lines.
class OutlinePainter extends CustomPainter {
  OutlinePainter({required this.picture, required this.view})
      : super(repaint: view);

  final ui.Picture picture;
  final ViewTransform view;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    view.apply(canvas);
    canvas.drawPicture(picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(OutlinePainter old) =>
      old.picture != picture || old.view != view;
}

/// Numbers shown inside regions that still need their color (color-by-number).
class NumbersPainter extends CustomPainter {
  NumbersPainter({required this.controller, required this.view})
      : super(repaint: Listenable.merge([controller, view]));

  final ColoringController controller;
  final ViewTransform view;
  final Map<String, TextPainter> _cache = {};

  TextPainter _label(int n, bool highlight, double fontSize) {
    final key = '$n-$highlight-${fontSize.round()}';
    return _cache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: '$n',
          style: TextStyle(
            fontFamily: 'Baloo',
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: highlight ? const Color(0xFFFF7A59) : const Color(0xFF6D5A4E),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final meta = controller.meta;
    if (meta == null) return;
    final sel = controller.selectedNumber;
    for (final r in controller.drawing.artRegions) {
      final m = meta.regions[r.id];
      if (m == null) continue;
      if (controller.state[r.id]?.fill == m.target) continue;
      final highlight = m.number == sel;
      // Font scales with the region but stays readable at any zoom.
      final docFont = (m.area <= 0 ? 30.0 : (m.area / 60).clamp(22.0, 54.0));
      final px = (docFont * view.scale).clamp(12.0, 34.0);
      final tp = _label(m.number, highlight, px);
      final c = view.toScreen(m.center);
      if (highlight) {
        canvas.drawCircle(c, tp.width.clamp(px * 0.6, 60.0) + 4,
            Paint()..color = const Color(0x55FFE0B2));
      }
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(NumbersPainter old) => true;
}
