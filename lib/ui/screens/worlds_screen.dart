import 'package:flutter/material.dart';

import '../../core/catalog.dart';
import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../core/settings.dart';
import '../../effects/sfx.dart';
import '../theme.dart';
import '../widgets/backdrop.dart';
import '../widgets/bouncy.dart';
import '../widgets/transitions.dart';
import 'coloring_screen.dart';
import 'drawings_screen.dart';

class WorldsScreen extends StatelessWidget {
  const WorldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cat = Catalog.instance;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(
          child: Backdrop(colors: [Color(0xFFFFE9B8), Color(0xFFFFD1E3)], floaters: ['⭐', '☁️', '🌈', '✨']),
        ),
        SafeArea(
          child: ListenableBuilder(
            listenable: Progress.instance,
            builder: (context, _) {
              final p = Progress.instance;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(children: [
                    RoundButton(icon: Icons.arrow_back_rounded, size: 54, onTap: () => Navigator.pop(context)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(s.worlds, style: CL.text(32, weight: 800))),
                    StarPill(stars: p.stars),
                  ]),
                ),
                Expanded(
                  child: LayoutBuilder(builder: (context, box) {
                    final cols = (box.maxWidth / 260).floor().clamp(2, 4).toInt();
                    return GridView.count(
                      crossAxisCount: cols,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.95,
                      children: [
                        for (var i = 0; i < cat.worlds.length; i++)
                          _AppearIn(index: i, child: _WorldCard(world: cat.worlds[i])),
                        _AppearIn(index: cat.worlds.length, child: const _FreeDrawCard()),
                      ],
                    );
                  }),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _AppearIn extends StatelessWidget {
  const _AppearIn({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + index * 70),
      curve: Curves.easeOutBack,
      builder: (context, v, c) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(0, (1 - v) * 40), child: c),
      ),
      child: child,
    );
  }
}

class _WorldCard extends StatefulWidget {
  const _WorldCard({required this.world});
  final WorldMeta world;
  @override
  State<_WorldCard> createState() => _WorldCardState();
}

class _WorldCardState extends State<_WorldCard> with SingleTickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final w = widget.world;
    final p = Progress.instance;
    final unlocked = p.worldUnlocked(w, unlockAll: Settings.instance.unlockAll);
    final total = Catalog.instance.drawingsIn(w.id).length;
    final done = p.completedIn(w.id, Catalog.instance);
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final x = _shake.isAnimating ? 10 * (1 - _shake.value) * (((_shake.value * 10).floor().isEven) ? 1 : -1) : 0.0;
        return Transform.translate(offset: Offset(x, 0), child: child);
      },
      child: Bouncy(
        onTap: () {
          if (!unlocked) {
            SoundFx.instance.play(Sfx.wrong);
            _shake.forward(from: 0);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: CL.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                content: Text('⭐ ${s.needStars(w.starsNeeded)}', style: CL.text(20, color: Colors.white)),
              ));
            return;
          }
          Navigator.of(context).push(popRoute(DrawingsScreen(world: w)));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: w.colors),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(color: CL.darker(w.colors.last, 0.2), offset: const Offset(0, 8)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 14)),
            ],
          ),
          child: Stack(children: [
            Positioned(
              right: -20, top: -20,
              child: Container(width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25))),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                  child: FittedBox(
                    child: Text(w.emoji, style: const TextStyle(fontSize: 80, shadows: [
                      Shadow(color: Color(0x33000000), offset: Offset(0, 6), blurRadius: 6),
                    ])),
                  ),
                ),
                Text(w.titleFor(s.lang),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CL.text(22, color: Colors.white, weight: 800)
                        .copyWith(shadows: [Shadow(color: CL.darker(w.colors.last, 0.3), offset: const Offset(0, 2))])),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: Text('$done / $total', style: CL.text(16)),
                ),
              ]),
            ),
            if (!unlocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(27),
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.lock_rounded, color: Colors.white, size: 54),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFFFD23F), size: 28),
                      Text('${w.starsNeeded}', style: CL.text(26, color: Colors.white)),
                    ]),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _FreeDrawCard extends StatelessWidget {
  const _FreeDrawCard();
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Bouncy(
      onTap: () => Navigator.of(context).push(popRoute(ColoringScreen.free())),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          border: Border.all(color: const Color(0xFF3EC1D3), width: 5),
          boxShadow: [
            const BoxShadow(color: Color(0xFF2A9FAE), offset: Offset(0, 8)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 14)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Expanded(child: FittedBox(child: Text('✏️', style: TextStyle(fontSize: 80)))),
          Text(s.freeDraw, style: CL.text(22, color: const Color(0xFF2A9FAE), weight: 800)),
        ]),
      ),
    );
  }
}
