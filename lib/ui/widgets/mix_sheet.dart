import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../effects/sfx.dart';
import '../theme.dart';
import 'bouncy.dart';

/// Paint-pot mixing with *pigment* logic (red + yellow = orange, yellow + blue
/// = green), not RGB averaging which would give kids muddy greys.
class ColorMixer {
  static const red = Color(0xFFE53935);
  static const yellow = Color(0xFFFFD23F);
  static const blue = Color(0xFF1E88E5);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF263238);
  static const bases = [red, yellow, blue, white, black];

  static final Map<String, Color> _table = {
    _k(red, yellow): const Color(0xFFFF8F1F),
    _k(yellow, blue): const Color(0xFF43A047),
    _k(red, blue): const Color(0xFF7E3FB8),
    _k(red, white): const Color(0xFFFF9EB5),
    _k(yellow, white): const Color(0xFFFFF3B0),
    _k(blue, white): const Color(0xFF90CAF9),
    _k(black, white): const Color(0xFF9E9E9E),
    _k(red, black): const Color(0xFF8E1F1F),
    _k(yellow, black): const Color(0xFF827717),
    _k(blue, black): const Color(0xFF1A237E),
  };

  static String _k(Color a, Color b) {
    final x = [a.toARGB32(), b.toARGB32()]..sort();
    return '${x[0]}-${x[1]}';
  }

  static Color mix(Color a, Color b) => a == b ? a : (_table[_k(a, b)] ?? Color.lerp(a, b, 0.5)!);
}

Future<Color?> showMixSheet(BuildContext context) => showModalBottomSheet<Color>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _MixSheet(),
    );

class _MixSheet extends StatefulWidget {
  const _MixSheet();
  @override
  State<_MixSheet> createState() => _MixSheetState();
}

class _MixSheetState extends State<_MixSheet> with SingleTickerProviderStateMixin {
  Color? _a, _b;
  late final AnimationController _swirl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _swirl.dispose();
    super.dispose();
  }

  void _pick(Color c) {
    setState(() {
      if (_a == null || (_a != null && _b != null)) {
        _a = c;
        _b = null;
      } else {
        _b = c;
        _swirl.forward(from: 0);
        SoundFx.instance.play(Sfx.magic, volume: 0.6);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mixed = (_a != null && _b != null) ? ColorMixer.mix(_a!, _b!) : null;
    // Same color twice is not a discovery.
    final result = (mixed == null || ColorMixer.bases.contains(mixed)) ? null : mixed;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 12),
          Text('🧪 ${s.mixColors}', style: CL.text(26)),
          Text(s.mixHint, style: CL.text(18, weight: 500, color: Colors.black54)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _slot(_a),
            Padding(padding: const EdgeInsets.all(10), child: Text('+', style: CL.text(36))),
            _slot(_b),
            Padding(padding: const EdgeInsets.all(10), child: Text('=', style: CL.text(36))),
            AnimatedBuilder(
              animation: _swirl,
              builder: (context, _) => _pot(result, _swirl.value),
            ),
          ]),
          const SizedBox(height: 18),
          Wrap(spacing: 14, children: [
            for (final c in ColorMixer.bases)
              Bouncy(
                onTap: () => _pick(c),
                child: Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE0E0E0), width: 3),
                    boxShadow: [BoxShadow(color: CL.darker(c, 0.2), offset: const Offset(0, 4))],
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 20),
          PillButton(
            label: s.addColor, emoji: '🎨', width: 280, height: 64, fontSize: 22,
            color: result ?? Colors.grey,
            onTap: result == null ? null : () => Navigator.pop(context, result),
          ),
        ]),
      ),
    );
  }

  Widget _slot(Color? c) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 70, height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c ?? const Color(0xFFF5F0EA),
          border: Border.all(color: const Color(0xFFE0D6CC), width: 3),
        ),
      );

  Widget _pot(Color? c, double t) {
    final color = c ?? const Color(0xFFF5F0EA);
    return SizedBox(
      width: 96, height: 96,
      child: CustomPaint(painter: _PotPainter(color, c == null ? 0 : t, _a, _b)),
    );
  }
}

class _PotPainter extends CustomPainter {
  _PotPainter(this.color, this.t, this.a, this.b);
  final Color color;
  final double t;
  final Color? a, b;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    canvas.drawCircle(c, r, Paint()..color = color);
    if (t > 0 && t < 1 && a != null && b != null) {
      // swirling streaks of the two source colors fading into the result
      for (var i = 0; i < 2; i++) {
        final p = Path();
        for (var k = 0; k <= 30; k++) {
          final ang = k / 30 * math.pi * 2.2 + t * 8 + i * math.pi;
          final rr = r * (k / 30) * 0.9;
          final pt = c + Offset(math.cos(ang) * rr, math.sin(ang) * rr);
          if (k == 0) {
            p.moveTo(pt.dx, pt.dy);
          } else {
            p.lineTo(pt.dx, pt.dy);
          }
        }
        canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round
            ..color = (i == 0 ? a! : b!).withValues(alpha: 1 - t),
        );
      }
    }
    canvas.drawCircle(c, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0xFF2B1B12));
    canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.4), r * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_PotPainter old) => true;
}
