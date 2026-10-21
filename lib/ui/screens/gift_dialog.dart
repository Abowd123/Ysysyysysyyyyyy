import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../effects/sfx.dart';
import '../theme.dart';
import '../widgets/bouncy.dart';

Future<void> showGiftDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _GiftDialog(),
    );

class _GiftDialog extends StatefulWidget {
  const _GiftDialog();
  @override
  State<_GiftDialog> createState() => _GiftDialogState();
}

class _GiftDialogState extends State<_GiftDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _opened = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _open() {
    if (_opened) return;
    final got = Progress.instance.claimGift();
    if (got == 0) return;
    SoundFx.instance.play(Sfx.gift);
    setState(() => _opened = true);
    _c.forward();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final available = Progress.instance.giftAvailable || _opened;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎁 ${s.dailyGift}', style: CL.text(28)),
          const SizedBox(height: 14),
          SizedBox(
            height: 170,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                final wiggle = _opened ? 0.0 : math.sin(DateTime.now().millisecondsSinceEpoch / 120) * 0.04;
                return Stack(alignment: Alignment.center, children: [
                  if (_opened)
                    Transform.scale(
                      scale: Curves.elasticOut.transform(t),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 90),
                        Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 90),
                      ]),
                    ),
                  Opacity(
                    opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: wiggle,
                      child: Transform.scale(
                        scale: 1 + t * 0.6,
                        child: Text(available ? '🎁' : '📦', style: const TextStyle(fontSize: 120)),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 10),
          if (_opened)
            Text(s.giftGot, style: CL.text(24, color: CL.primary))
          else if (!available)
            Text(s.giftTomorrow, style: CL.text(20), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          PillButton(
            label: _opened || !available ? s.done : s.giftOpen,
            emoji: _opened || !available ? '👍' : '✨',
            width: 260, height: 64, fontSize: 22,
            onTap: _opened || !available ? () => Navigator.pop(context) : _open,
          ),
        ]),
      ),
    );
  }
}
