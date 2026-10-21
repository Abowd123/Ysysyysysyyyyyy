import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

enum ParticleShape { star, circle, confetti }

class Particle {
  Particle({
    required this.pos,
    required this.vel,
    required this.life,
    required this.size,
    required this.color,
    required this.shape,
    this.gravity = 900,
    this.drag = 0.9,
    this.spin = 0,
  }) : maxLife = life;

  Offset pos;
  Offset vel;
  double life;
  final double maxLife;
  final double size;
  final Color color;
  final ParticleShape shape;
  final double gravity;
  final double drag;
  final double spin;
  double rotation = 0;

  double get t => 1 - (life / maxLife).clamp(0.0, 1.0);
}

/// Lightweight particle system in screen space (independent of zoom).
class ParticleSystem extends ChangeNotifier {
  final List<Particle> _items = [];
  final math.Random _rnd = math.Random();
  static const int maxParticles = 400;

  bool get isActive => _items.isNotEmpty;
  List<Particle> get items => _items;

  double _r(double a, double b) => a + _rnd.nextDouble() * (b - a);

  Color _tint(Color c, double amount) =>
      Color.lerp(c, const Color(0xFFFFFFFF), amount) ?? c;

  /// Star burst when a region gets filled.
  void burst(Offset at, Color color, {int count = 16}) {
    for (var i = 0; i < count; i++) {
      final a = _r(0, math.pi * 2);
      final speed = _r(180, 420);
      _add(Particle(
        pos: at,
        vel: Offset(math.cos(a), math.sin(a)) * speed,
        life: _r(0.45, 0.8),
        size: _r(7, 14),
        color: i.isEven ? color : _tint(color, 0.6),
        shape: i % 3 == 0 ? ParticleShape.circle : ParticleShape.star,
        gravity: 500,
        drag: 0.86,
        spin: _r(-6, 6),
      ));
    }
    notifyListeners();
  }

  /// Small glitter left behind by the brush.
  void sparkle(Offset at, Color color) {
    _add(Particle(
      pos: at + Offset(_r(-8, 8), _r(-8, 8)),
      vel: Offset(_r(-40, 40), _r(-120, -30)),
      life: _r(0.3, 0.55),
      size: _r(4, 8),
      color: _tint(color, 0.5),
      shape: ParticleShape.star,
      gravity: 120,
      drag: 0.92,
      spin: _r(-4, 4),
    ));
    notifyListeners();
  }

  /// Full-screen celebration.
  void confetti(Size area) {
    const colors = [
      Color(0xFFFF5A5F), Color(0xFFFFC93C), Color(0xFF3EC1D3),
      Color(0xFF7BC86C), Color(0xFFA66CFF), Color(0xFFFF8FB1),
    ];
    for (var i = 0; i < 140; i++) {
      _add(Particle(
        pos: Offset(_r(0, area.width), _r(-60, -10)),
        vel: Offset(_r(-80, 80), _r(80, 260)),
        life: _r(1.8, 3.0),
        size: _r(8, 15),
        color: colors[i % colors.length],
        shape: i % 4 == 0 ? ParticleShape.star : ParticleShape.confetti,
        gravity: 140,
        drag: 0.99,
        spin: _r(-8, 8),
      ));
    }
    notifyListeners();
  }

  void _add(Particle p) {
    if (_items.length >= maxParticles) _items.removeAt(0);
    _items.add(p);
  }

  /// [dt] in seconds.
  void update(double dt) {
    if (_items.isEmpty) return;
    for (final p in _items) {
      p.life -= dt;
      final d = math.pow(p.drag, dt * 60).toDouble();
      p.vel = Offset(p.vel.dx * d, p.vel.dy * d + p.gravity * dt);
      p.pos += p.vel * dt;
      p.rotation += p.spin * dt;
    }
    _items.removeWhere((p) => p.life <= 0);
    notifyListeners();
  }
}

class ParticlePainter extends CustomPainter {
  ParticlePainter(this.system) : super(repaint: system);
  final ParticleSystem system;

  static final Path _star = _buildStar();

  static Path _buildStar() {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 1.0 : 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    for (final p in system.items) {
      final fade = p.t < 0.7 ? 1.0 : (1 - (p.t - 0.7) / 0.3);
      final pop = p.t < 0.15 ? (p.t / 0.15) : 1.0;
      final s = p.size * (0.6 + 0.4 * pop);
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.rotation);
      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, s * 0.5, paint);
        case ParticleShape.star:
          canvas.scale(s);
          canvas.drawPath(_star, paint);
        case ParticleShape.confetti:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: s, height: s * 0.5),
                const Radius.circular(2)),
            paint,
          );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticlePainter old) => old.system != system;
}
