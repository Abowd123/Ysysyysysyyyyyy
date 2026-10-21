import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../core/catalog.dart';
import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../core/settings.dart';
import '../../effects/particle_layer.dart';
import '../../effects/particles.dart';
import '../../effects/sfx.dart';
import '../../engine/coloring_document.dart';
import '../../engine/living.dart';
import '../../engine/svg_drawing.dart';
import '../theme.dart';
import '../widgets/bouncy.dart';
import '../widgets/lolo.dart';

/// The hero moment: the child's drawing jumps off the page and moves.
class LivingScreen extends StatefulWidget {
  const LivingScreen({super.key, required this.drawing, required this.meta, required this.state});
  final SvgDrawing drawing;
  final DrawingMeta? meta;
  final DocState state;

  @override
  State<LivingScreen> createState() => _LivingScreenState();
}

class _LivingScreenState extends State<LivingScreen> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _time = ValueNotifier(0);
  late final Ticker _ticker = createTicker((d) => _time.value = d.inMicroseconds / 1e6);
  final ParticleSystem _particles = ParticleSystem();
  bool _showReward = false;
  int _earned = 0;
  Timer? _voiceTimer;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    SoundFx.instance.play(Sfx.life);
    WidgetsBinding.instance.addPostFrameCallback((_) => _burst());
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      SoundFx.instance.voice(widget.meta?.sound ?? 'twinkle');
      if (Settings.instance.haptics) HapticFeedback.mediumImpact();
    });
    // Award after the first frame: notifying listeners during build would
    // rebuild screens underneath mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.meta?.id;
      if (id != null && mounted) _earned = Progress.instance.bringToLife(id);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showReward = true);
      if (_earned > 0) SoundFx.instance.play(Sfx.star);
    });
    // The character "talks" now and then.
    _voiceTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      SoundFx.instance.voice(widget.meta?.sound ?? 'twinkle', volume: 0.6);
    });
  }

  void _burst() {
    final size = MediaQuery.sizeOf(context);
    final c = Offset(size.width / 2, size.height / 2);
    _particles.burst(c, const Color(0xFFFFD23F), count: 40);
    _particles.burst(c, const Color(0xFFA66CFF), count: 24);
    _particles.burst(c, const Color(0xFFFF8FB1), count: 24);
  }

  void _replay() {
    _ticker.stop();
    _time.value = 0;
    _ticker.start();
    SoundFx.instance.play(Sfx.life);
    Future.delayed(const Duration(milliseconds: 600), () => SoundFx.instance.voice(widget.meta?.sound ?? 'twinkle'));
    _burst();
  }

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _ticker.dispose();
    _time.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Stack(children: [
        // spotlight stage
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.0,
                colors: [CL.lighter(widget.meta?.bg ?? const Color(0xFFFFF3B0), 0.05), const Color(0xFF3B2A7A)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(children: [
                RoundButton(icon: Icons.arrow_back_rounded, size: 54, onTap: () => Navigator.pop(context)),
                const Spacer(),
                StarPill(stars: Progress.instance.stars),
              ]),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  SoundFx.instance.voice(widget.meta?.sound ?? 'twinkle');
                  final size = MediaQuery.sizeOf(context);
                  _particles.burst(Offset(size.width / 2, size.height * 0.45), const Color(0xFFFFD23F), count: 14);
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 20))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: CustomPaint(
                            painter: LivingPainter(
                              drawing: widget.drawing,
                              state: widget.state,
                              meta: widget.meta,
                              time: _time,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSlide(
              offset: _showReward ? Offset.zero : const Offset(0, 1.5),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Lolo(size: 90, mood: LoloMood.cheer, interactive: false),
                  const SizedBox(width: 10),
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.alive, style: CL.text(26, color: Colors.white, weight: 800)),
                    if (_earned > 0)
                      Row(children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFD23F), size: 30),
                        Text('+$_earned', style: CL.text(24, color: const Color(0xFFFFD23F))),
                      ]),
                  ]),
                  const SizedBox(width: 16),
                  RoundButton(icon: Icons.replay_rounded, size: 58, onTap: _replay),
                ]),
              ),
            ),
          ]),
        ),
        Positioned.fill(child: ParticleLayer(system: _particles)),
      ]),
    );
  }
}
