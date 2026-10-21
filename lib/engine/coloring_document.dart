import 'dart:ui';

/// How a stroke is rendered. Order matters: the index is stored in saves.
enum BrushStyle { normal, neon, crayon, watercolor, glitter }

/// A finished brush stroke, always owned by (and clipped to) one region.
class BrushStroke {
  BrushStroke({
    required this.regionId,
    required this.color,
    required this.width,
    required List<Offset> points,
    this.style = BrushStyle.normal,
  }) : points = List.unmodifiable(points);

  final String regionId;
  final Color color;
  final double width;
  final List<Offset> points;
  final BrushStyle style;

  Map<String, dynamic> toJson() => {
        'r': regionId,
        'c': color.toARGB32(),
        'w': _round(width),
        if (style != BrushStyle.normal) 'st': style.index,
        'p': [
          for (final p in points) ...[_round(p.dx), _round(p.dy)]
        ],
      };

  static BrushStroke fromJson(Map<String, dynamic> j) {
    final raw = (j['p'] as List).cast<num>();
    final pts = <Offset>[
      for (var i = 0; i + 1 < raw.length; i += 2)
        Offset(raw[i].toDouble(), raw[i + 1].toDouble())
    ];
    final st = (j['st'] as int?) ?? 0;
    return BrushStroke(
      regionId: j['r'] as String,
      color: Color(j['c'] as int),
      width: (j['w'] as num).toDouble(),
      points: pts,
      style: BrushStyle.values[st.clamp(0, BrushStyle.values.length - 1)],
    );
  }

  static double _round(double v) => (v * 10).roundToDouble() / 10;
}

/// What is painted inside one region: an optional bucket fill + strokes on top.
class RegionPaint {
  const RegionPaint({this.fill, this.strokes = const []});

  final Color? fill;
  final List<BrushStroke> strokes;

  bool get isPainted => fill != null || strokes.isNotEmpty;

  RegionPaint withStroke(BrushStroke s) =>
      RegionPaint(fill: fill, strokes: List.unmodifiable([...strokes, s]));

  Map<String, dynamic> toJson() => {
        if (fill != null) 'f': fill!.toARGB32(),
        if (strokes.isNotEmpty) 's': [for (final s in strokes) s.toJson()],
      };

  static RegionPaint fromJson(Map<String, dynamic> j) => RegionPaint(
        fill: j['f'] == null ? null : Color(j['f'] as int),
        strokes: List.unmodifiable([
          for (final s in (j['s'] as List? ?? const []))
            BrushStroke.fromJson((s as Map).cast<String, dynamic>())
        ]),
      );
}

/// Immutable snapshot of the whole artwork. Cheap to keep in undo history
/// because unchanged regions are shared between snapshots.
class DocState {
  const DocState._(this.regions);

  static const DocState empty = DocState._({});
  static const int schemaVersion = 1;

  final Map<String, RegionPaint> regions;

  RegionPaint? operator [](String id) => regions[id];

  DocState withFill(String regionId, Color color) => DocState._(
      Map.unmodifiable({...regions, regionId: RegionPaint(fill: color)}));

  DocState withStroke(BrushStroke s) {
    final current = regions[s.regionId] ?? const RegionPaint();
    return DocState._(
        Map.unmodifiable({...regions, s.regionId: current.withStroke(s)}));
  }

  /// Several fills in one step (magic wand).
  DocState withFills(Map<String, Color> fills) => DocState._(Map.unmodifiable({
        ...regions,
        for (final e in fills.entries) e.key: RegionPaint(fill: e.value),
      }));

  int paintedCount(Iterable<String> ids) =>
      ids.where((id) => regions[id]?.isPainted ?? false).length;

  Map<String, dynamic> toJson(String drawingId) => {
        'v': schemaVersion,
        'drawing': drawingId,
        'regions': {
          for (final e in regions.entries)
            if (e.value.isPainted) e.key: e.value.toJson()
        },
      };

  static DocState fromJson(Map<String, dynamic> j) {
    final raw = (j['regions'] as Map? ?? const {}).cast<String, dynamic>();
    return DocState._(Map.unmodifiable({
      for (final e in raw.entries)
        e.key: RegionPaint.fromJson((e.value as Map).cast<String, dynamic>())
    }));
  }
}

/// Linear undo / redo over [DocState] snapshots.
class History {
  History({this.limit = 100});

  final int limit;
  final List<DocState> _undo = [];
  final List<DocState> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(DocState previous) {
    _undo.add(previous);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }

  DocState? undo(DocState current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  DocState? redo(DocState current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
