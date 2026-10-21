import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

import 'coloring_document.dart';
import 'painters.dart';
import 'svg_drawing.dart';

/// Renders an artwork (paint + line art) to a high-resolution PNG.
Future<Uint8List?> renderArtworkPng(SvgDrawing drawing, DocState state,
    {ui.Color paper = const ui.Color(0xFFFFFDF7), int size = 2048}) async {
  final rec = ui.PictureRecorder();
  final k = size / drawing.size.width;
  final canvas = ui.Canvas(rec);
  canvas.scale(k);
  paintArtwork(canvas, drawing, state, paper);
  for (final o in drawing.outline) {
    if (o.aliveOnly) continue;
    canvas.drawPath(o.path, o.paint);
  }
  final pic = rec.endRecording();
  final img = await pic.toImage(size, (drawing.size.height * k).round());
  pic.dispose();
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return data?.buffer.asUint8List();
}

/// Saves the artwork to the phone's photo gallery (album "ColorLand").
/// Returns true on success. Never throws.
Future<bool> exportToDeviceGallery(SvgDrawing drawing, DocState state,
    {ui.Color paper = const ui.Color(0xFFFFFDF7)}) async {
  try {
    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) return false;
    }
    final png = await renderArtworkPng(drawing, state, paper: paper);
    if (png == null) return false;
    await Gal.putImageBytes(png,
        album: 'ColorLand',
        name: 'colorland_${drawing.id}_${DateTime.now().millisecondsSinceEpoch}');
    return true;
  } catch (e) {
    debugPrint('export failed: $e');
    return false;
  }
}
