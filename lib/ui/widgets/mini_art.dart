import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../engine/coloring_document.dart';
import '../../engine/mini_art_painter.dart';
import '../../engine/svg_drawing.dart';

/// Thumbnail of a drawing with its saved colors (or blank line art).
class MiniArt extends StatelessWidget {
  const MiniArt({super.key, required this.drawingId, this.state, this.paper});
  final String drawingId;
  final DocState? state;
  final Color? paper;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SvgDrawing>(
      future: Catalog.instance.svgFor(drawingId),
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) return const SizedBox.expand();
        return RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: MiniArtPainter(
              drawing: d,
              state: state ?? DocState.empty,
              paper: paper ?? const Color(0xFFFFFDF7),
            ),
          ),
        );
      },
    );
  }
}
