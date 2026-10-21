import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/catalog.dart';
import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../effects/sfx.dart';
import '../../engine/artwork_storage.dart';
import '../../engine/coloring_document.dart';
import '../../engine/living.dart';
import '../../engine/svg_drawing.dart';
import '../theme.dart';
import '../widgets/backdrop.dart';
import '../widgets/bouncy.dart';
import '../widgets/lolo.dart';

/// Every drawing the child brought to life keeps living here.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});
  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6);
  List<(DrawingMeta, SvgDrawing, DocState)>? _items;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    _load();
  }

  Future<void> _load() async {
    final out = <(DrawingMeta, SvgDrawing, DocState)>[];
    for (final id in Progress.instance.alive) {
      final m = Catalog.instance.drawing(id);
      if (m == null) continue;
      final st = await ArtworkStorage.load(id);
      if (st == null) continue;
      out.add((m, await Catalog.instance.svgFor(id), st));
    }
    if (mounted) setState(() => _items = out);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = _items;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: Backdrop(colors: [Color(0xFFBDEBFF), Color(0xFFC8F7DC)], floaters: ['🦋', '🌼', '☁️', '🌸'])),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF9BE15D), Color(0xFF5CB85C)]),
              borderRadius: BorderRadius.vertical(top: Radius.elliptical(600, 90)),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(children: [
                RoundButton(icon: Icons.arrow_back_rounded, size: 54, onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text('🌳 ${s.garden}', style: CL.text(32, weight: 800))),
              ]),
            ),
            Expanded(
              child: items == null
                  ? const SizedBox()
                  : items.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Lolo(size: 160, mood: LoloMood.think),
                            const SizedBox(height: 10),
                            Text(s.emptyGarden, style: CL.text(24), textAlign: TextAlign.center),
                          ]),
                        )
                      : LayoutBuilder(builder: (context, box) {
                          final cols = math.max(2, (box.maxWidth / 220).floor());
                          return GridView.count(
                            crossAxisCount: cols,
                            padding: const EdgeInsets.all(16),
                            children: [
                              for (final (m, d, st) in items)
                                GestureDetector(
                                  onTap: () => SoundFx.instance.voice(m.sound),
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      painter: LivingPainter(
                                        drawing: d, state: st, meta: m, time: _time,
                                        showBackground: false,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
            ),
          ]),
        ),
      ]),
    );
  }
}
