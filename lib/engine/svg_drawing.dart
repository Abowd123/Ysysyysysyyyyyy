import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

/// One closed, colorable area of a drawing.
///
/// [visiblePath] is the region minus every region painted above it, so a fill
/// or a brush stroke clipped to it can never leak into a neighbour.
class ColorRegion {
  ColorRegion({
    required this.id,
    required this.visiblePath,
    Path? rawPath,
    this.part = 'body',
    this.strokeWhenAlive = true,
  })  : rawPath = rawPath ?? visiblePath,
        bounds = visiblePath.getBounds();

  final String id;
  final Path visiblePath;

  /// The full shape before hiding what lies above it. Used by the
  /// bring-to-life animator, where parts move independently.
  final Path rawPath;

  /// Animation group (head, tail, eyes...).
  final String part;
  final bool strokeWhenAlive;
  final Rect bounds;

  bool contains(Offset p) => bounds.contains(p) && visiblePath.contains(p);
}

/// A non-colorable line-art element (outline, pupils, shine...).
class OutlineItem {
  const OutlineItem(this.path, this.paint,
      {this.isEdge = false, this.aliveOnly = false, this.part = 'body'});
  final Path path;
  final Paint paint;

  /// Edges trace region borders (static view only); details (faces, pupils,
  /// decorations) move with their part when the drawing comes alive.
  final bool isEdge;

  /// Drawn only in the bring-to-life view (full borders of scenery).
  final bool aliveOnly;
  final String part;
}

/// Parsed coloring page.
///
/// SVG convention (see tools/gen_lion.py):
/// `<g id="regions">` holds one `<path id="...">` per colorable area, bottom to top.
/// `<g id="outline">` holds the line art drawn on top of everything.
class SvgDrawing {
  SvgDrawing._({
    required this.id,
    required this.size,
    required this.regions,
    required this.outline,
  }) : _byId = {for (final r in regions) r.id: r};

  static const String backgroundId = 'background';

  final String id;
  final Size size;

  /// Bottom to top. Index 0 is always the implicit background.
  final List<ColorRegion> regions;
  final List<OutlineItem> outline;
  final Map<String, ColorRegion> _byId;

  Rect get rect => Offset.zero & size;

  ColorRegion? region(String id) => _byId[id];

  /// Colorable regions excluding the background.
  Iterable<ColorRegion> get artRegions =>
      regions.where((r) => r.id != backgroundId);

  /// Topmost region under [p] (document coordinates).
  ColorRegion? hitTest(Offset p) {
    if (!rect.contains(p)) return null;
    for (var i = regions.length - 1; i >= 0; i--) {
      if (regions[i].contains(p)) return regions[i];
    }
    return null;
  }

  /// Empty page for free drawing: a single full-page region, no line art.
  factory SvgDrawing.blank(String id, {Size size = const Size(1000, 1000)}) {
    final path = Path()..addRect(Offset.zero & size);
    return SvgDrawing._(
      id: id,
      size: size,
      regions: [ColorRegion(id: backgroundId, visiblePath: path)],
      outline: const [],
    );
  }

  /// Bounds of every region in [part] (used as a default pivot).
  Rect partBounds(String part) {
    Rect? r;
    for (final reg in regions) {
      if (reg.part != part) continue;
      final b = reg.rawPath.getBounds();
      r = r == null ? b : r.expandToInclude(b);
    }
    return r ?? rect;
  }

  static Future<SvgDrawing> loadAsset(String id, String assetPath) async =>
      parse(id, await rootBundle.loadString(assetPath));

  static SvgDrawing parse(String id, String svgSource) {
    final doc = XmlDocument.parse(svgSource);
    final root = doc.rootElement;

    final vb = (root.getAttribute('viewBox') ?? '0 0 1000 1000')
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.parse)
        .toList();
    final origin = Offset(-vb[0], -vb[1]);
    final size = Size(vb[2], vb[3]);

    Path parsePath(XmlElement e, {String attr = 'd'}) {
      final p = parseSvgPathData(e.getAttribute(attr) ?? '');
      final shifted = origin == Offset.zero ? p : p.shift(origin);
      shifted.fillType = PathFillType.evenOdd;
      return shifted;
    }

    // ---- regions ----
    final rawRegions = <(String, Path)>[];
    final precomputed = <Path?>[];
    final parts = <String>[];
    final strokes = <bool>[];
    final regionGroup = _findGroup(root, 'regions');
    if (regionGroup != null) {
      for (final e in _paths(regionGroup)) {
        final rid = e.getAttribute('id');
        if (rid == null || rid.isEmpty) continue;
        rawRegions.add((rid, parsePath(e)));
        precomputed.add(e.getAttribute('data-vis') == null
            ? null
            : parsePath(e, attr: 'data-vis'));
        parts.add(e.getAttribute('data-part') ?? 'body');
        strokes.add(e.getAttribute('data-stroke') != '0');
      }
    }

    // Make regions disjoint from the top down, then add the background.
    // Fast path: the art pipeline ships the visible shapes (no boolean ops).
    final visible = List<Path?>.filled(rawRegions.length, null);
    final bgGroup = _findGroup(root, 'background');
    final bgElement = bgGroup == null ? null : _paths(bgGroup).firstOrNull;
    final fast = rawRegions.isNotEmpty &&
        precomputed.every((p) => p != null) &&
        bgElement?.getAttribute('data-vis') != null;
    Path? occupied;
    for (var i = rawRegions.length - 1; i >= 0 && !fast; i--) {
      final path = rawRegions[i].$2;
      if (occupied == null) {
        visible[i] = path;
        occupied = Path.from(path);
      } else {
        visible[i] = Path.combine(PathOperation.difference, path, occupied);
        occupied = Path.combine(PathOperation.union, occupied, path);
      }
    }
    if (fast) {
      for (var i = 0; i < rawRegions.length; i++) {
        visible[i] = precomputed[i];
      }
    }
    final canvasPath = Path()..addRect(Offset.zero & size);
    final Path bgPath;
    if (fast) {
      bgPath = parsePath(bgElement!, attr: 'data-vis');
    } else {
      bgPath = occupied == null
          ? canvasPath
          : Path.combine(PathOperation.difference, canvasPath, occupied);
    }

    final regions = <ColorRegion>[
      ColorRegion(id: backgroundId, visiblePath: bgPath),
      for (var i = 0; i < rawRegions.length; i++)
        ColorRegion(
          id: rawRegions[i].$1,
          visiblePath: visible[i]!,
          rawPath: rawRegions[i].$2,
          part: parts[i],
          strokeWhenAlive: strokes[i],
        ),
    ];

    // ---- outline ----
    final outline = <OutlineItem>[];
    final outlineGroup = _findGroup(root, 'outline');
    if (outlineGroup != null) {
      final groupCap = outlineGroup.getAttribute('stroke-linecap');
      for (final e in _paths(outlineGroup)) {
        final path = parsePath(e)..fillType = PathFillType.nonZero;
        final fill = _parseColor(e.getAttribute('fill'));
        final stroke = _parseColor(e.getAttribute('stroke'));
        final kind = e.getAttribute('data-kind');
        final isEdge = kind == 'edge';
        final aliveOnly = kind == 'alive';
        final part = e.getAttribute('data-part') ?? 'body';
        if (fill != null) {
          outline.add(OutlineItem(
            path,
            Paint()
              ..isAntiAlias = true
              ..style = PaintingStyle.fill
              ..color = fill,
            isEdge: isEdge,
            aliveOnly: aliveOnly,
            part: part,
          ));
        }
        if (stroke != null) {
          final w = double.tryParse(e.getAttribute('stroke-width') ?? '') ?? 8;
          outline.add(OutlineItem(
            path,
            Paint()
              ..isAntiAlias = true
              ..style = PaintingStyle.stroke
              ..strokeWidth = w
              ..strokeCap =
                  groupCap == 'butt' ? StrokeCap.butt : StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            isEdge: isEdge,
            aliveOnly: aliveOnly,
            part: part,
          ));
        }
      }
    }

    return SvgDrawing._(
      id: id,
      size: size,
      regions: regions,
      outline: outline,
    );
  }

  static XmlElement? _findGroup(XmlElement root, String id) {
    for (final e in root.descendants.whereType<XmlElement>()) {
      if (e.name.local == 'g' && e.getAttribute('id') == id) return e;
    }
    return null;
  }

  static Iterable<XmlElement> _paths(XmlElement group) => group.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 'path');

  static Color? _parseColor(String? v) {
    if (v == null) return null;
    var h = v.trim();
    if (h.isEmpty || h == 'none') return null;
    if (!h.startsWith('#')) return null;
    h = h.substring(1);
    if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
    if (h.length != 6) return null;
    return Color(int.parse('FF$h', radix: 16));
  }
}
