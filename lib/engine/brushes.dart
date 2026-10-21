import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'coloring_document.dart';

/// Procedural tiling textures, generated once at startup (no image assets).
class TextureBank {
  TextureBank._();
  static ui.Image? crayon;
  static ui.Image? glitter;
  static bool get ready => crayon != null && glitter != null;

  static final Float64List _identity = Float64List.fromList(
      [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);

  static void init() {
    if (ready) return;
    crayon = _make(128, (c, rnd) {
      c.drawRect(const Rect.fromLTWH(0, 0, 128, 128),
          Paint()..color = const Color(0xD9FFFFFF));
      final p = Paint();
      for (var i = 0; i < 1400; i++) {
        p.color = Color.fromARGB(255 - rnd.nextInt(60), 255, 255, 255);
        c.drawCircle(Offset(rnd.nextDouble() * 128, rnd.nextDouble() * 128),
            0.6 + rnd.nextDouble() * 1.2, p);
      }
      p.blendMode = BlendMode.dstOut;
      for (var i = 0; i < 700; i++) {
        p.color = Color.fromARGB(120 + rnd.nextInt(130), 0, 0, 0);
        // Slightly elongated specks read as paper grain.
        final o = Offset(rnd.nextDouble() * 128, rnd.nextDouble() * 128);
        c.drawOval(Rect.fromCenter(center: o, width: 2.6, height: 1.2), p);
      }
    });
    glitter = _make(96, (c, rnd) {
      final p = Paint();
      for (var i = 0; i < 160; i++) {
        final o = Offset(rnd.nextDouble() * 96, rnd.nextDouble() * 96);
        p.color = Color.fromARGB(110 + rnd.nextInt(145), 255, 255, 255);
        c.drawCircle(o, 0.7 + rnd.nextDouble() * 1.6, p);
      }
      p.color = const Color(0xFFFFFFFF);
      p.strokeWidth = 1.2;
      for (var i = 0; i < 10; i++) {
        final o = Offset(rnd.nextDouble() * 96, rnd.nextDouble() * 96);
        final s = 3 + rnd.nextDouble() * 4;
        c.drawLine(o - Offset(s, 0), o + Offset(s, 0), p);
        c.drawLine(o - Offset(0, s), o + Offset(0, s), p);
      }
    });
  }

  static ui.Image _make(int size, void Function(Canvas, math.Random) draw) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
    draw(c, math.Random(size));
    final pic = rec.endRecording();
    final img = pic.toImageSync(size, size);
    pic.dispose();
    return img;
  }

  static Shader? shader(ui.Image? img, {double scale = 1}) {
    if (img == null) return null;
    final m = Float64List.fromList(_identity);
    m[0] = scale;
    m[5] = scale;
    return ImageShader(img, TileMode.repeated, TileMode.repeated, m);
  }
}

/// Smooth path through the sampled points (quadratic curves via midpoints).
Path buildStrokePath(List<Offset> pts) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts.first.dx, pts.first.dy);
  if (pts.length == 1) {
    path.lineTo(pts.first.dx + 0.01, pts.first.dy);
    return path;
  }
  for (var i = 1; i < pts.length - 1; i++) {
    final p = pts[i];
    final n = pts[i + 1];
    path.quadraticBezierTo(p.dx, p.dy, (p.dx + n.dx) / 2, (p.dy + n.dy) / 2);
  }
  path.lineTo(pts.last.dx, pts.last.dy);
  return path;
}

Paint strokePaint(Color color, double width) => Paint()
  ..isAntiAlias = true
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..strokeWidth = width
  ..color = color;

/// Draws one stroke in its style. The caller sets up clipping.
void drawStroke(Canvas canvas, List<Offset> points, Color color, double width,
    BrushStyle style) {
  final path = buildStrokePath(points);
  switch (style) {
    case BrushStyle.normal:
      canvas.drawPath(path, strokePaint(color, width));
    case BrushStyle.neon:
      // Halo (blurred, wide) + bright core: glows on any background.
      canvas.drawPath(
        path,
        strokePaint(color.withValues(alpha: 0.85), width * 1.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.45),
      );
      canvas.drawPath(path, strokePaint(color, width * 0.75));
      canvas.drawPath(
        path,
        strokePaint(Color.lerp(color, const Color(0xFFFFFFFF), 0.75)!,
            width * 0.32),
      );
    case BrushStyle.crayon:
      final shader = TextureBank.shader(TextureBank.crayon, scale: 0.8);
      final p = strokePaint(color, width);
      if (shader != null) {
        p
          ..shader = shader
          ..colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
      }
      canvas.drawPath(path, p);
    case BrushStyle.watercolor:
      canvas.drawPath(
        path,
        strokePaint(color.withValues(alpha: 0.38), width * 1.15)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.18),
      );
      canvas.drawPath(path, strokePaint(color.withValues(alpha: 0.30), width * 0.7));
    case BrushStyle.glitter:
      canvas.drawPath(path, strokePaint(color, width));
      final shader = TextureBank.shader(TextureBank.glitter);
      if (shader != null) {
        canvas.drawPath(path, strokePaint(color, width)..shader = shader);
      }
  }
}
