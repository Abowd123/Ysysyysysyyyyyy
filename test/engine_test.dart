import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:colorland/core/catalog.dart';
import 'package:colorland/engine/artwork_export.dart';
import 'package:colorland/engine/coloring_controller.dart';
import 'package:colorland/engine/coloring_document.dart';
import 'package:colorland/engine/svg_drawing.dart';
import 'package:colorland/ui/widgets/mix_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Catalog catalog;
  final svgs = <String, SvgDrawing>{};

  setUpAll(() {
    catalog = Catalog.fromJsonString(File('assets/catalog.json').readAsStringSync());
    for (final d in catalog.drawings) {
      svgs[d.id] = SvgDrawing.parse(d.id, File(d.svg).readAsStringSync());
    }
  });

  Offset insidePoint(ColorRegion r) {
    final b = r.bounds;
    for (var y = b.top + 1; y <= b.bottom; y += 2) {
      for (var x = b.left + 1; x <= b.right; x += 2) {
        if (r.contains(Offset(x, y))) return Offset(x, y);
      }
    }
    throw StateError('no inside point for ${r.id}');
  }

  test('catalog: 7 worlds, every world has drawings', () {
    expect(catalog.worlds.length, 7);
    for (final w in catalog.worlds) {
      expect(catalog.drawingsIn(w.id), isNotEmpty, reason: w.id);
    }
  });

  test('every drawing parses and matches its meta', () {
    for (final d in catalog.drawings) {
      final svg = svgs[d.id]!;
      final ids = svg.artRegions.map((r) => r.id).toSet();
      expect(ids, d.regions.keys.toSet(), reason: d.id);
      expect(svg.regions.first.id, SvgDrawing.backgroundId);
      expect(svg.outline, isNotEmpty, reason: d.id);
    }
  });

  test('label centers hit their own region (no leaking between areas)', () {
    for (final d in catalog.drawings) {
      final svg = svgs[d.id]!;
      for (final e in d.regions.entries) {
        expect(svg.hitTest(e.value.center)?.id, e.key, reason: '${d.id}/${e.key}');
      }
    }
  });

  test('regions are disjoint', () {
    final svg = svgs['lion_01']!;
    for (var x = 5.0; x < 1000; x += 37) {
      for (var y = 5.0; y < 1000; y += 41) {
        final owners = svg.regions.where((r) => r.contains(Offset(x, y))).length;
        expect(owners, lessThanOrEqualTo(1));
      }
    }
  });

  test('fill, stroke, undo, redo', () {
    final c = ColoringController(drawing: svgs['lion_01']!, meta: catalog.drawing('lion_01'));
    final nose = catalog.drawing('lion_01')!.regions['nose']!.center;
    c.color = const Color(0xFFFF0000);
    c.fillAt(nose);
    expect(c.state['nose']?.fill, const Color(0xFFFF0000));
    c.tool = Tool.brush;
    c.style = BrushStyle.crayon;
    final belly = catalog.drawing('lion_01')!.regions['belly']!.center;
    expect(c.beginStroke(belly), isTrue);
    c.extendStroke(belly + const Offset(10, 10));
    c.endStroke();
    expect(c.state['belly']?.strokes.single.style, BrushStyle.crayon);
    c.undo();
    expect(c.state['belly'], isNull);
    c.undo();
    expect(c.state['nose'], isNull);
    c.redo();
    expect(c.state['nose']?.fill, const Color(0xFFFF0000));
  });

  test('magic wand completes the page in one undo step', () {
    final c = ColoringController(drawing: svgs['cat_01']!, meta: catalog.drawing('cat_01'));
    var completed = 0;
    c.onEffect = (e) {
      if (e.kind == EffectKind.completed) completed++;
    };
    c.wandAt(const Offset(500, 500));
    expect(c.isCompleted, isTrue);
    expect(completed, 1);
    c.undo();
    expect(c.state.regions, isEmpty);
  });

  test('color by number rejects the wrong color', () {
    final meta = catalog.drawing('fish_01')!;
    final c = ColoringController(drawing: svgs['fish_01']!, meta: meta, mode: ColoringMode.numbers);
    final eye = meta.regions['eye']!;
    final wrong = meta.palette.firstWhere((p) => p != eye.target);
    var wrongCount = 0;
    c.onEffect = (e) {
      if (e.kind == EffectKind.wrong) wrongCount++;
    };
    c.color = wrong;
    c.fillAt(eye.center);
    expect(wrongCount, 1);
    expect(c.state['eye'], isNull);
    c.color = eye.target;
    c.fillAt(eye.center);
    expect(c.state['eye']?.fill, eye.target);
  });

  test('completion fires once for manual fills', () {
    final svg = svgs['house_01']!;
    final c = ColoringController(drawing: svg, meta: catalog.drawing('house_01'));
    var completed = 0;
    c.onEffect = (e) {
      if (e.kind == EffectKind.completed) completed++;
    };
    for (final r in svg.artRegions) {
      c.fillAt(insidePoint(r));
    }
    expect(c.isCompleted, isTrue);
    expect(completed, 1);
  });

  test('free drawing: blank page, brush anywhere, never "completes"', () {
    final c = ColoringController(drawing: SvgDrawing.blank('free_1'), mode: ColoringMode.free);
    expect(c.tool, Tool.brush);
    expect(c.beginStroke(const Offset(10, 990)), isTrue);
    c.endStroke();
    expect(c.hasContent, isTrue);
    expect(c.isCompleted, isFalse);
  });

  test('json round trip keeps strokes, styles and fills', () {
    final s = DocState.empty.withFill('mane', const Color(0xFFD9822B)).withStroke(BrushStroke(
          regionId: 'face',
          color: const Color(0xFF00FF00),
          width: 28,
          style: BrushStyle.neon,
          points: const [Offset(1.23, 4.56), Offset(7, 8)],
        ));
    final back = DocState.fromJson(jsonDecode(jsonEncode(s.toJson('lion_01'))) as Map<String, dynamic>);
    expect(back['mane']?.fill, const Color(0xFFD9822B));
    expect(back['face']?.strokes.single.points.first, const Offset(1.2, 4.6));
    expect(back['face']?.strokes.single.style, BrushStyle.neon);
  });

  test('pigment mixing behaves like real paint', () {
    final green = ColorMixer.mix(ColorMixer.yellow, ColorMixer.blue);
    expect(green.g > green.r && green.g > green.b, isTrue);
    expect(ColorMixer.mix(ColorMixer.red, ColorMixer.yellow), ColorMixer.mix(ColorMixer.yellow, ColorMixer.red));
  });

  test('picking a color after the eraser returns to the brush', () {
    final c = ColoringController(drawing: svgs['lion_01']!, meta: catalog.drawing('lion_01'));
    c.tool = Tool.eraser;
    c.color = const Color(0xFF00FF00);
    expect(c.tool, Tool.brush);
  });

  testWidgets('export renders a real PNG', (tester) async {
    final svg = svgs['lion_01']!;
    final st = DocState.empty.withFill('mane', const Color(0xFFD9822B));
    final png = await tester.runAsync(() => renderArtworkPng(svg, st, size: 256));
    expect(png, isNotNull);
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });
}
