import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated 2.5D sky: gradient + slowly drifting clouds/emoji at different
/// depths (parallax). Cheap: one ticker, one CustomPaint for the blobs.
class Backdrop extends StatefulWidget {
  const Backdrop({
    super.key,
    this.colors = const [Color(0xFFBFE8FF), Color(0xFFFFE3EF)],
    this.floaters = const ['☁️', '☁️', '⭐', '🎈'],
    this.dark = false,
  });

  final List<Color> colors;
  final List<String> floaters;
  final bool dark;

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.colors,
        ),
      ),
      child: LayoutBuilder(builder: (context, box) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final items = <Widget>[];
            final rnd = math.Random(7);
            for (var i = 0; i < 9; i++) {
              final depth = 0.4 + rnd.nextDouble() * 0.6;
              final y = rnd.nextDouble() * box.maxHeight * 0.9;
              final speed = 0.6 + depth;
              final x = ((rnd.nextDouble() + t * speed) % 1.2 - 0.1) * box.maxWidth;
              final bob = math.sin((t * 40 + i) * 1.3) * 8;
              final emoji = widget.floaters[i % widget.floaters.length];
              items.add(Positioned(
                left: x,
                top: y + bob,
                child: Opacity(
                  opacity: 0.35 + depth * 0.5,
                  child: Text(emoji, style: TextStyle(fontSize: 26 + depth * 40)),
                ),
              ));
            }
            return Stack(children: [
              // soft light blobs
              Positioned(
                left: -80, top: -60,
                child: _blob(260, Colors.white.withValues(alpha: widget.dark ? 0.08 : 0.5)),
              ),
              Positioned(
                right: -60, bottom: -40,
                child: _blob(300, Colors.white.withValues(alpha: widget.dark ? 0.06 : 0.35)),
              ),
              ...items,
            ]);
          },
        );
      }),
    );
  }

  Widget _blob(double s, Color c) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
      );
}
