import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/settings.dart';
import '../../effects/sfx.dart';
import '../theme.dart';

/// Squashes on press and springs back, with a click sound.
class Bouncy extends StatefulWidget {
  const Bouncy({super.key, required this.child, this.onTap, this.sound = true});
  final Widget child;
  final VoidCallback? onTap;
  final bool sound;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              if (widget.sound) SoundFx.instance.play(Sfx.click, volume: 0.5);
              if (Settings.instance.haptics) HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.86 : 1,
        duration: Duration(milliseconds: _down ? 70 : 380),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Round 2.5D button: glossy face + solid "lip" shadow underneath.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color = Colors.white,
    this.iconColor = CL.ink,
    this.size = 56,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final face = selected ? CL.primary : color;
    return Bouncy(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 0.95,
            colors: [CL.lighter(face, 0.12), face],
          ),
          border: Border.all(color: Colors.white, width: selected ? 4 : 3),
          boxShadow: [
            BoxShadow(color: CL.darker(face, 0.25), offset: const Offset(0, 5)),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Icon(icon,
            size: size * 0.5, color: selected ? Colors.white : iconColor),
      ),
    );
  }
}

/// Big pill button used on the home screen and dialogs.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.emoji,
    this.color = CL.primary,
    this.height = 76,
    this.width,
    this.fontSize = 26,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? emoji;
  final Color color;
  final double height;
  final double? width;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [CL.lighter(color, 0.1), color],
          ),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(color: CL.darker(color, 0.22), offset: const Offset(0, 7)),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null)
              Text(emoji!, style: TextStyle(fontSize: fontSize * 1.1)),
            if (icon != null) Icon(icon, color: Colors.white, size: fontSize * 1.2),
            if (emoji != null || icon != null) const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: CL.text(fontSize, color: Colors.white, weight: 800).copyWith(
                  shadows: [Shadow(color: CL.darker(color, 0.3), offset: const Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stars counter pill.
class StarPill extends StatelessWidget {
  const StarPill({super.key, required this.stars, this.onTap});
  final int stars;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Bouncy(
      onTap: onTap,
      sound: onTap != null,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0xFFE6D6C6), offset: Offset(0, 5))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 34),
          const SizedBox(width: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(end: stars.toDouble()),
            duration: const Duration(milliseconds: 700),
            builder: (context, v, _) => Text('${v.round()}', style: CL.text(24)),
          ),
        ]),
      ),
    );
  }
}
