import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../effects/sfx.dart';

enum LoloMood { idle, happy, cheer, think, sleep }

/// Lolo: the app's mascot, drawn in code (no image assets) so she can blink,
/// bounce, squash and recolor her beret live.
class Lolo extends StatefulWidget {
  const Lolo({
    super.key,
    this.size = 180,
    this.mood = LoloMood.idle,
    this.beret = const Color(0xFFA66CFF),
    this.onTap,
    this.interactive = true,
  });

  final double size;
  final LoloMood mood;
  final Color beret;
  final VoidCallback? onTap;
  final bool interactive;

  @override
  State<Lolo> createState() => LoloState();
}

class LoloState extends State<Lolo> with TickerProviderStateMixin {
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  late final AnimationController _jump = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750));
  final math.Random _rnd = math.Random();

  /// Makes Lolo jump (also called from parent widgets on events).
  void jump({bool sound = true}) {
    _jump.forward(from: 0);
    if (sound) SoundFx.instance.play(Sfx.giggle, volume: 0.6);
  }

  @override
  void didUpdateWidget(Lolo old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood && widget.mood == LoloMood.cheer) {
      jump(sound: false);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.interactive
          ? () {
              jump();
              widget.onTap?.call();
            }
          : null,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.12,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _jump]),
          builder: (context, _) => CustomPaint(
            painter: _LoloPainter(
              t: _idle.value,
              jump: _jump.value,
              mood: widget.mood,
              beret: widget.beret,
              blinkSeed: _rnd.hashCode,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoloPainter extends CustomPainter {
  _LoloPainter({
    required this.t,
    required this.jump,
    required this.mood,
    required this.beret,
    required this.blinkSeed,
  });

  final double t;
  final double jump;
  final LoloMood mood;
  final Color beret;
  final int blinkSeed;

  static const ink = Color(0xFF2B1B12);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512;
    canvas.save();
    canvas.scale(s);

    // --- motion
    final breath = math.sin(t * 2 * math.pi);
    double dy = breath * 6;
    double sx = 1 + breath * 0.012, sy = 1 - breath * 0.012;
    if (jump > 0) {
      final j = jump;
      if (j < 0.18) {
        final k = j / 0.18; // anticipation squash
        sx += 0.10 * k;
        sy -= 0.12 * k;
      } else if (j < 0.62) {
        final k = (j - 0.18) / 0.44;
        dy -= math.sin(k * math.pi) * 120;
        sx -= 0.06 * math.sin(k * math.pi);
        sy += 0.08 * math.sin(k * math.pi);
      } else {
        final k = (j - 0.62) / 0.38; // landing wobble
        final w = math.sin(k * math.pi * 3) * math.exp(-k * 3);
        sx += 0.10 * w;
        sy -= 0.10 * w;
      }
    }
    if (mood == LoloMood.cheer) dy -= (math.sin(t * 8 * math.pi)).abs() * 18;

    // shadow
    final shadowK = 1 - (-dy / 160).clamp(0.0, 0.6);
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(256, 548), width: 300 * shadowK, height: 46 * shadowK),
      Paint()..color = Colors.black.withValues(alpha: 0.13),
    );

    canvas.translate(256, 520 + dy);
    canvas.scale(sx, sy);
    canvas.translate(-256, -520);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = ink;

    // brush (behind body), waves when cheering
    final brushAngle = mood == LoloMood.cheer
        ? math.sin(t * 6 * math.pi) * 0.35
        : math.sin(t * 2 * math.pi) * 0.08;
    canvas.save();
    canvas.translate(380, 330);
    canvas.rotate(-0.55 + brushAngle);
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -170, 24, 180), const Radius.circular(12)),
        Paint()..color = const Color(0xFF8D6E63));
    canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -170, 24, 180), const Radius.circular(12)),
        stroke..strokeWidth = 8);
    final tip = Path()
      ..moveTo(-24, -170)
      ..quadraticBezierTo(-30, -230, 0, -262)
      ..quadraticBezierTo(30, -230, 24, -170)
      ..close();
    canvas.drawPath(tip, Paint()..color = beret);
    canvas.drawPath(tip, stroke);
    canvas.restore();
    stroke.strokeWidth = 11;

    // body
    final bodyRect = Rect.fromCenter(center: const Offset(256, 340), width: 320, height: 300);
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xFFFFF6EE), Color(0xFFFFC9B5)],
        ).createShader(bodyRect),
    );
    canvas.drawOval(bodyRect, stroke);

    // feet
    for (final x in [190.0, 322.0]) {
      final r = Rect.fromCenter(center: Offset(x, 492), width: 92, height: 48);
      canvas.drawOval(r, Paint()..color = const Color(0xFFFFB59A));
      canvas.drawOval(r, stroke);
    }

    // beret
    final b = Path()
      ..moveTo(104, 236)
      ..quadraticBezierTo(116, 120, 256, 118)
      ..quadraticBezierTo(402, 122, 410, 236)
      ..quadraticBezierTo(256, 190, 104, 236)
      ..close();
    canvas.drawPath(b, Paint()..color = beret);
    canvas.drawPath(b, stroke);
    canvas.drawCircle(const Offset(256, 112), 20, Paint()..color = const Color(0xFFFFD23F));
    canvas.drawCircle(const Offset(256, 112), 20, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(150, 190)
        ..quadraticBezierTo(190, 150, 250, 146),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.45),
    );

    // eyes
    final cycle = (t * 3) % 1.0;
    final blink = cycle > 0.94 ? math.sin((cycle - 0.94) / 0.06 * math.pi) : 0.0;
    final sleepy = mood == LoloMood.sleep;
    for (final x in [204.0, 308.0]) {
      if (sleepy || mood == LoloMood.happy || mood == LoloMood.cheer) {
        // happy closed eyes ^ ^ (or sleeping)
        final p = Path()
          ..moveTo(x - 26, 336)
          ..quadraticBezierTo(x, sleepy ? 350 : 306, x + 26, 336);
        canvas.drawPath(p, stroke);
      } else {
        final h = 72 * (1 - blink * 0.92);
        final r = Rect.fromCenter(center: Offset(x, 330), width: 60, height: h);
        canvas.drawOval(r, Paint()..color = ink);
        if (blink < 0.5) {
          final look = mood == LoloMood.think ? const Offset(8, -10) : Offset.zero;
          canvas.drawCircle(Offset(x + 10, 316) + look, 11, Paint()..color = Colors.white);
          canvas.drawCircle(Offset(x - 8, 344) + look, 5, Paint()..color = Colors.white);
        }
      }
    }
    // cheeks
    for (final x in [164.0, 348.0]) {
      canvas.drawCircle(Offset(x, 376), 22,
          Paint()..color = const Color(0xFFFF8FB1).withValues(alpha: 0.8));
    }
    // mouth
    if (mood == LoloMood.cheer || mood == LoloMood.happy) {
      final m = Path()
        ..moveTo(222, 384)
        ..quadraticBezierTo(256, 440, 290, 384)
        ..close();
      canvas.drawPath(m, Paint()..color = const Color(0xFFE53935));
      canvas.drawPath(m, stroke);
    } else if (sleepy) {
      canvas.drawCircle(const Offset(256, 396), 10, stroke);
    } else if (mood == LoloMood.think) {
      canvas.drawLine(const Offset(236, 396), const Offset(276, 390), stroke);
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(226, 386)
            ..quadraticBezierTo(256, 416, 286, 386),
          stroke);
    }
    // hand holding the brush
    final hand = Rect.fromCenter(center: const Offset(380, 356), width: 74, height: 64);
    canvas.drawOval(hand, Paint()..color = const Color(0xFFFFE3D6));
    canvas.drawOval(hand, stroke);

    if (sleepy) {
      final tp = TextPainter(
        text: const TextSpan(text: 'z z', style: TextStyle(fontSize: 70, color: ink, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(400, 120 - math.sin(t * 2 * math.pi) * 10));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoloPainter old) => true;
}
