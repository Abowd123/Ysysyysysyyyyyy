import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../engine/artwork_storage.dart';
import '../../engine/coloring_document.dart';
import '../theme.dart';
import '../widgets/artwork_actions.dart';
import '../widgets/backdrop.dart';
import '../widgets/bouncy.dart';
import '../widgets/lolo.dart';
import '../widgets/mini_art.dart';
import '../widgets/transitions.dart';
import 'coloring_screen.dart';
import 'living_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<(String, DocState)>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = (await ArtworkStorage.list())
        .where((id) => Catalog.isFreeId(id) || Catalog.instance.drawing(id) != null)
        .toList();
    final states = await Future.wait(ids.map(ArtworkStorage.load));
    final out = <(String, DocState)>[
      for (var i = 0; i < ids.length; i++)
        if (states[i] != null && states[i]!.regions.isNotEmpty) (ids[i], states[i]!),
    ];
    if (mounted) setState(() => _items = out);
  }

  Future<void> _more(String id, DocState st) async {
    final a = await showArtworkActions(context, id, st);
    if (!mounted) return;
    if (a == ArtworkAction.open) {
      await Navigator.of(context).push(popRoute(ColoringScreen.resume(id)));
      _load();
    } else if (a == ArtworkAction.deleted) {
      _load();
    }
  }

  Future<void> _open(String id, DocState st) async {
    final p = Progress.instance;
    if (p.alive.contains(id)) {
      final d = await Catalog.instance.svgFor(id);
      if (!mounted) return;
      await Navigator.of(context).push(popRoute(LivingScreen(drawing: d, meta: Catalog.instance.drawing(id), state: st)));
    } else {
      await Navigator.of(context).push(popRoute(ColoringScreen.resume(id)));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = _items;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: Backdrop(colors: [Color(0xFFE8DCFF), Color(0xFFFFE3EF)], floaters: ['🖼️', '⭐', '🎨'])),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(children: [
                RoundButton(icon: Icons.arrow_back_rounded, size: 54, onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text(s.gallery, style: CL.text(32, weight: 800))),
              ]),
            ),
            if (items != null && items.isNotEmpty)
              Text('👆 ${s.galleryHint}', style: CL.text(16, weight: 500, color: Colors.black54)),
            Expanded(
              child: items == null
                  ? const Center(child: CircularProgressIndicator(color: CL.primary))
                  : items.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const Lolo(size: 160, mood: LoloMood.think),
                            const SizedBox(height: 12),
                            Text(s.emptyGallery, style: CL.text(24), textAlign: TextAlign.center),
                          ]),
                        )
                      : LayoutBuilder(builder: (context, box) {
                          final cols = (box.maxWidth / 240).floor().clamp(2, 5).toInt();
                          return GridView.builder(
                            padding: const EdgeInsets.all(18),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols, mainAxisSpacing: 18, crossAxisSpacing: 18),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final (id, st) = items[i];
                              final alive = Progress.instance.alive.contains(id);
                              return GestureDetector(
                                onLongPress: () => _more(id, st),
                                child: Bouncy(
                                onTap: () => _open(id, st),
                                child: Container(
                                  // A little wooden frame.
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    gradient: const LinearGradient(colors: [Color(0xFFD7A86E), Color(0xFFB07A44)]),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 8))],
                                  ),
                                  child: Stack(children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: MiniArt(drawingId: id, state: st,
                                            paper: Catalog.isFreeId(id) ? Colors.white : null),
                                      ),
                                    ),
                                    if (alive)
                                      const Positioned(
                                        top: 4, left: 4,
                                        child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFA66CFF), size: 30),
                                      ),
                                  ]),
                                ),
                              ),
                              );
                            },
                          );
                        }),
            ),
          ]),
        ),
      ]),
    );
  }
}
