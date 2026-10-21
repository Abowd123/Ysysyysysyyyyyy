import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../core/settings.dart';
import '../../effects/sfx.dart';
import '../../engine/artwork_storage.dart';
import '../../engine/coloring_controller.dart';
import '../../engine/coloring_document.dart';
import '../theme.dart';
import '../widgets/backdrop.dart';
import '../widgets/bouncy.dart';
import '../widgets/mini_art.dart';
import '../widgets/transitions.dart';
import 'coloring_screen.dart';

const _worldFloaters = <String, List<String>>{
  'animals': ['🐾', '🍃', '☁️', '🦋'],
  'vehicles': ['☁️', '🚦', '⭐', '💨'],
  'fantasy': ['✨', '⭐', '🌙', '💫'],
  'sea': ['🫧', '🐚', '🫧', '🐟'],
  'space': ['⭐', '✨', '🌟', '🪐'],
  'nature': ['🌸', '🍃', '🌼', '🦋'],
  'home': ['🎈', '⭐', '🧸', '☁️'],
};

class DrawingsScreen extends StatefulWidget {
  const DrawingsScreen({super.key, required this.world});
  final WorldMeta world;

  @override
  State<DrawingsScreen> createState() => _DrawingsScreenState();
}

class _DrawingsScreenState extends State<DrawingsScreen> {
  final Map<String, DocState?> _saved = {};

  @override
  void initState() {
    super.initState();
    SoundFx.instance.music(widget.world.music);
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final list = Catalog.instance.drawingsIn(widget.world.id);
    final states = await Future.wait(list.map((d) => ArtworkStorage.load(d.id)));
    for (var i = 0; i < list.length; i++) {
      _saved[list[i].id] = states[i];
    }
    if (mounted) setState(() {});
  }

  Future<void> _open(DrawingMeta d) async {
    final mode = await showModeChooser(context, d);
    if (mode == null || !mounted) return;
    await Navigator.of(context).push(popRoute(ColoringScreen(meta: d, mode: mode)));
    SoundFx.instance.music(widget.world.music);
    _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final w = widget.world;
    final list = Catalog.instance.drawingsIn(w.id);
    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: Backdrop(
            colors: [CL.lighter(w.colors.first, 0.08), w.colors.last],
            floaters: _worldFloaters[w.id] ?? const ['⭐'],
            dark: w.id == 'space',
          ),
        ),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(children: [
                RoundButton(icon: Icons.arrow_back_rounded, size: 54, onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Text(w.emoji, style: const TextStyle(fontSize: 38)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(w.titleFor(s.lang),
                      overflow: TextOverflow.ellipsis,
                      style: CL.text(30, color: Colors.white, weight: 800).copyWith(
                          shadows: [Shadow(color: CL.darker(w.colors.last, 0.3), offset: const Offset(0, 3))])),
                ),
                StarPill(stars: Progress.instance.stars),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final cols = (box.maxWidth / 280).floor().clamp(2, 4).toInt();
                return GridView.builder(
                  padding: const EdgeInsets.all(18),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols, mainAxisSpacing: 18, crossAxisSpacing: 18, childAspectRatio: 0.86),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _DrawingCard(
                    meta: list[i],
                    saved: _saved[list[i].id],
                    onTap: () => _open(list[i]),
                  ),
                );
              }),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DrawingCard extends StatelessWidget {
  const _DrawingCard({required this.meta, required this.saved, required this.onTap});
  final DrawingMeta meta;
  final DocState? saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final p = Progress.instance;
    final done = p.completed.contains(meta.id);
    final alive = p.alive.contains(meta.id);
    return Bouncy(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: [
            const BoxShadow(color: Color(0x33000000), offset: Offset(0, 7)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(children: [
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: MiniArt(drawingId: meta.id, state: saved),
                ),
              ),
              if (done)
                const Positioned(top: 6, right: 6, child: _Badge(icon: Icons.check_rounded, color: Color(0xFF43A047))),
              if (alive)
                const Positioned(top: 6, left: 6, child: _Badge(icon: Icons.auto_awesome_rounded, color: Color(0xFFA66CFF))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Text(meta.titleFor(s.lang),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: CL.text(19)),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      );
}

/// "How do you want to color?" Little kids skip color-by-number.
Future<ColoringMode?> showModeChooser(BuildContext context, DrawingMeta d) {
  final s = S.of(context);
  final little = Settings.instance.age == AgeMode.little;
  return showDialog<ColoringMode>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            width: 200,
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: MiniArt(drawingId: d.id),
            ),
          ),
          const SizedBox(height: 12),
          Text(s.chooseMode, style: CL.text(24)),
          const SizedBox(height: 16),
          PillButton(
            label: s.classic, emoji: '🎨', width: 300, height: 66, fontSize: 22,
            onTap: () => Navigator.pop(ctx, ColoringMode.classic),
          ),
          const SizedBox(height: 12),
          PillButton(
            label: s.magic, emoji: '✨', width: 300, height: 66, fontSize: 22,
            color: const Color(0xFFA66CFF),
            onTap: () => Navigator.pop(ctx, ColoringMode.magic),
          ),
          if (!little) ...[
            const SizedBox(height: 12),
            PillButton(
              label: s.numbers, emoji: '🔢', width: 300, height: 66, fontSize: 22,
              color: const Color(0xFF3EC1D3),
              onTap: () => Navigator.pop(ctx, ColoringMode.numbers),
            ),
          ],
        ]),
      ),
    ),
  );
}
