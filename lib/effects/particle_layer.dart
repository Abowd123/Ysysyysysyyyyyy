import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'particles.dart';

/// Paints a [ParticleSystem] and drives it with a ticker only while alive.
class ParticleLayer extends StatefulWidget {
  const ParticleLayer({super.key, required this.system});
  final ParticleSystem system;

  @override
  State<ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<ParticleLayer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.system.addListener(_wake);
  }

  void _wake() {
    if (widget.system.isActive && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    widget.system.update(dt.clamp(0.0, 0.05));
    if (!widget.system.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    widget.system.removeListener(_wake);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(painter: ParticlePainter(widget.system)),
        ),
      );
}
