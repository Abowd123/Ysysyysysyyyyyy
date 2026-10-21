import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import '../engine/svg_drawing.dart';

Color hexColor(String h) {
  var s = h.replaceFirst('#', '');
  if (s.length == 6) s = 'FF$s';
  return Color(int.parse(s, radix: 16));
}

class RegionMeta {
  const RegionMeta(this.number, this.target, this.center, this.area);
  final int number;
  final Color target;
  final Offset center;
  final double area;
}

class AnimSpec {
  const AnimSpec({
    required this.type,
    this.pivot,
    this.amp = 10,
    this.speed = 1,
    this.phase = 0,
    this.follow,
  });
  final String type;
  final Offset? pivot;
  final double amp;
  final double speed;
  final double phase;
  final String? follow;

  static AnimSpec fromJson(Map<String, dynamic> j) {
    final p = j['pivot'] as List?;
    return AnimSpec(
      type: j['type'] as String,
      pivot: p == null
          ? null
          : Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      amp: (j['amp'] as num?)?.toDouble() ?? 10,
      speed: (j['speed'] as num?)?.toDouble() ?? 1,
      phase: (j['phase'] as num?)?.toDouble() ?? 0,
      follow: j['follow'] as String?,
    );
  }
}

class DrawingMeta {
  DrawingMeta({
    required this.id,
    required this.world,
    required this.title,
    required this.svg,
    required this.bg,
    required this.sound,
    required this.difficulty,
    required this.palette,
    required this.regions,
    required this.anim,
  });

  final String id;
  final String world;
  final Map<String, String> title;
  final String svg;
  final Color bg;
  final String sound;
  final int difficulty;

  /// Unique target colors; number N = palette[N-1].
  final List<Color> palette;
  final Map<String, RegionMeta> regions;
  final Map<String, AnimSpec> anim;

  String titleFor(String lang) => title[lang] ?? title['ar'] ?? id;

  static DrawingMeta fromJson(Map<String, dynamic> j) => DrawingMeta(
        id: j['id'] as String,
        world: j['world'] as String,
        title: (j['title'] as Map).cast<String, String>(),
        svg: j['svg'] as String,
        bg: hexColor(j['bg'] as String),
        sound: j['sound'] as String? ?? 'magic',
        difficulty: j['difficulty'] as int? ?? 1,
        palette: [for (final c in j['palette'] as List) hexColor(c as String)],
        regions: {
          for (final r in j['regions'] as List)
            (r as Map)['id'] as String: RegionMeta(
              r['number'] as int,
              hexColor(r['target'] as String),
              Offset((r['center'][0] as num).toDouble(),
                  (r['center'][1] as num).toDouble()),
              (r['area'] as num).toDouble(),
            )
        },
        anim: {
          for (final e in ((j['anim'] as Map?) ?? const {}).entries)
            e.key as String:
                AnimSpec.fromJson((e.value as Map).cast<String, dynamic>())
        },
      );
}

class WorldMeta {
  WorldMeta({
    required this.id,
    required this.emoji,
    required this.title,
    required this.colors,
    required this.starsNeeded,
    required this.music,
  });
  final String id;
  final String emoji;
  final Map<String, String> title;
  final List<Color> colors;
  final int starsNeeded;
  final String music;

  String titleFor(String lang) => title[lang] ?? title['ar'] ?? id;

  static WorldMeta fromJson(Map<String, dynamic> j) => WorldMeta(
        id: j['id'] as String,
        emoji: j['emoji'] as String,
        title: (j['title'] as Map).cast<String, String>(),
        colors: [for (final c in j['colors'] as List) hexColor(c as String)],
        starsNeeded: j['stars'] as int? ?? 0,
        music: j['music'] as String? ?? 'music_meadow',
      );
}

/// Every world and drawing shipped in the app (assets/catalog.json).
class Catalog {
  Catalog._(this.worlds, this.drawings);

  static Catalog? _instance;
  static Catalog get instance => _instance!;

  /// Null before [load] (used by achievement checks).
  static Catalog? get maybeInstance => _instance;

  final List<WorldMeta> worlds;
  final List<DrawingMeta> drawings;
  final Map<String, Future<SvgDrawing>> _svgCache = {};

  static Future<Catalog> load() async {
    if (_instance != null) return _instance!;
    final j = jsonDecode(await rootBundle.loadString('assets/catalog.json'))
        as Map<String, dynamic>;
    return _instance = Catalog._(
      [
        for (final w in j['worlds'] as List)
          WorldMeta.fromJson((w as Map).cast<String, dynamic>())
      ],
      [
        for (final d in j['drawings'] as List)
          DrawingMeta.fromJson((d as Map).cast<String, dynamic>())
      ],
    );
  }

  /// For tests.
  static Catalog fromJsonString(String s) {
    final j = jsonDecode(s) as Map<String, dynamic>;
    return Catalog._(
      [for (final w in j['worlds'] as List) WorldMeta.fromJson((w as Map).cast())],
      [for (final d in j['drawings'] as List) DrawingMeta.fromJson((d as Map).cast())],
    );
  }

  WorldMeta? world(String id) {
    for (final w in worlds) {
      if (w.id == id) return w;
    }
    return null;
  }

  DrawingMeta? drawing(String id) {
    for (final d in drawings) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<DrawingMeta> drawingsIn(String worldId) =>
      drawings.where((d) => d.world == worldId).toList();

  static bool isFreeId(String id) => id.startsWith('free_');

  /// Parsed SVG, cached for the whole session.
  Future<SvgDrawing> svgFor(String id) {
    if (isFreeId(id)) return Future.value(SvgDrawing.blank(id));
    return _svgCache.putIfAbsent(id, () {
      final meta = drawing(id);
      if (meta == null) return Future.error(StateError('Unknown drawing $id'));
      // A failed load must not stay cached forever.
      return SvgDrawing.loadAsset(id, meta.svg).catchError((Object e) {
        _svgCache.remove(id);
        throw e;
      });
    });
  }
}
