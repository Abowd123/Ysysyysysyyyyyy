import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'coloring_document.dart';
import 'painters.dart';
import 'svg_drawing.dart';

/// Static thumbnail: the artwork (or target colors when [preview]) + line art.
class MiniArtPainter extends CustomPainter {
  MiniArtPainter({
    required this.drawing,
    required this.state,
    this.paper = const Color(0xFFFFFDF7),
  });

  final SvgDrawing drawing;
  final DocState state;
  final Color paper;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width / drawing.size.width,
        size.height / drawing.size.height);
    canvas.save();
    canvas.translate((size.width - drawing.size.width * k) / 2,
        (size.height - drawing.size.height * k) / 2);
    canvas.scale(k);
    canvas.clipRect(drawing.rect);
    paintArtwork(canvas, drawing, state, paper);
    for (final o in drawing.outline) {
      if (o.aliveOnly) continue;
      canvas.drawPath(o.path, o.paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MiniArtPainter old) =>
      old.state != state || old.drawing != drawing;
}
