import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../theme.dart';
import '../widgets/backdrop.dart';
import '../widgets/bouncy.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final p = Progress.instance;
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: Backdrop(colors: [Color(0xFFFFF0B8), Color(0xFFFFD6A5)], floaters: ['⭐', '🏆', '✨'])),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(children: [
                RoundButton(icon: Icons.arrow_back_rounded, size: 54, onTap: () => Navigator.pop(context)),
                const SizedBox(width: 12),
                Expanded(child: Text('🏆 ${s.achievements}', style: CL.text(32, weight: 800))),
                StarPill(stars: p.stars),
              ]),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                final cols = (box.maxWidth / 170).floor().clamp(2, 6).toInt();
                return GridView.count(
                  crossAxisCount: cols,
                  padding: const EdgeInsets.all(16),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.9,
                  children: [
                    for (final a in Progress.achievements)
                      _BadgeTile(emoji: a.emoji, title: a.titleFor(s.lang), owned: p.badges.contains(a.id)),
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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.emoji, required this.title, required this.owned});
  final String emoji;
  final String title;
  final bool owned;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: owned ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: owned ? const Color(0xFFFFC93C) : Colors.white, width: 4),
        boxShadow: owned ? const [BoxShadow(color: Color(0xFFE0A800), offset: Offset(0, 6))] : null,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Expanded(
          child: FittedBox(
            child: owned
                ? Text(emoji, style: const TextStyle(fontSize: 60))
                : const Icon(Icons.lock_rounded, size: 60, color: Colors.black26),
          ),
        ),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, maxLines: 2,
            style: CL.text(16, color: owned ? CL.ink : Colors.black38)),
      ]),
    );
  }
}
