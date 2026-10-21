import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../core/settings.dart';
import '../../effects/sfx.dart';
import '../theme.dart';
import '../widgets/backdrop.dart';
import '../widgets/bouncy.dart';
import '../widgets/lolo.dart';
import '../widgets/parental_gate.dart';
import '../widgets/transitions.dart';
import 'achievements_screen.dart';
import 'coloring_screen.dart';
import 'gallery_screen.dart';
import 'garden_screen.dart';
import 'gift_dialog.dart';
import 'settings_screen.dart';
import 'worlds_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<LoloState> _lolo = GlobalKey();
  String? _bubble;
  Timer? _bubbleTimer;
  LoloMood _mood = LoloMood.happy;

  @override
  void initState() {
    super.initState();
    SoundFx.instance.music('music_meadow');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _say(S.current.loloHello);
      SoundFx.instance.play(Sfx.hello, volume: 0.6);
      _lolo.currentState?.jump(sound: false);
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _say(String text) {
    setState(() => _bubble = text);
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  Future<void> _go(Widget page) async {
    await Navigator.of(context).push(popRoute(page));
    SoundFx.instance.music('music_meadow');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([Progress.instance, Settings.instance]),
        builder: (context, _) {
          final p = Progress.instance;
          return Stack(children: [
            const Positioned.fill(
              child: Backdrop(
                colors: [Color(0xFFAEE2FF), Color(0xFFFFE3EF)],
                floaters: ['☁️', '☁️', '⭐', '🎈', '🦋'],
              ),
            ),
            // floating island
            const Align(alignment: Alignment(0, 0.22), child: _Island()),
            SafeArea(
              child: LayoutBuilder(builder: (context, box) {
                final wide = box.maxWidth > box.maxHeight;
                final loloSize = (wide ? box.maxHeight * 0.42 : box.maxWidth * 0.5).clamp(140.0, 300.0);
                final title = Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('ColorLand',
                      style: CL.text(wide ? 40.0 : 46.0, color: Colors.white, weight: 800).copyWith(
                        shadows: const [Shadow(color: Color(0xFFFF7A59), offset: Offset(0, 4), blurRadius: 0)],
                      )),
                  Text(s.appName,
                      style: CL.text(wide ? 26.0 : 30.0, color: CL.primary, weight: 800)),
                ]);
                final lolo = Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
                  Lolo(
                    key: _lolo,
                    size: loloSize,
                    mood: _mood,
                    onTap: () {
                      _say(s.loloTap);
                      setState(() => _mood = LoloMood.cheer);
                      Future.delayed(const Duration(milliseconds: 900), () {
                        if (mounted) setState(() => _mood = LoloMood.happy);
                      });
                    },
                  ),
                  if (_bubble != null)
                    Positioned(top: -16, child: _SpeechBubble(text: _bubble!)),
                ]);
                final buttons = Column(mainAxisSize: MainAxisSize.min, children: [
                  PillButton(
                    label: s.startColoring, emoji: '🎨', color: CL.primary, width: 320,
                    onTap: () => _go(const WorldsScreen()),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: s.freeDraw, emoji: '✏️', color: const Color(0xFF3EC1D3), width: 320,
                    onTap: () => _go(ColoringScreen.free()),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: s.myGallery, emoji: '🖼️', color: const Color(0xFFA66CFF), width: 320,
                    onTap: () => _go(const GalleryScreen()),
                  ),
                ]);
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Row(children: [
                      StarPill(stars: p.stars, onTap: () => _go(const AchievementsScreen())),
                      const SizedBox(width: 10),
                      // Buttons shrink instead of overflowing on narrow phones.
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              _GiftButton(
                                available: p.giftAvailable,
                                onTap: () async {
                                  await showGiftDialog(context);
                                  if (mounted) setState(() {});
                                },
                              ),
                              const SizedBox(width: 10),
                              RoundButton(icon: Icons.emoji_events_rounded, size: 54,
                                  iconColor: const Color(0xFFFFB300),
                                  onTap: () => _go(const AchievementsScreen())),
                              const SizedBox(width: 10),
                              RoundButton(icon: Icons.park_rounded, size: 54,
                                  iconColor: const Color(0xFF43A047),
                                  onTap: () => _go(const GardenScreen())),
                              const SizedBox(width: 10),
                              RoundButton(
                                icon: Settings.instance.music ? Icons.music_note_rounded : Icons.music_off_rounded,
                                size: 54,
                                onTap: () => Settings.instance.music = !Settings.instance.music,
                              ),
                              const SizedBox(width: 10),
                              RoundButton(
                                icon: Icons.settings_rounded, size: 54,
                                onTap: () async {
                                  final ok = await showParentalGate(context);
                                  if (ok && mounted) _go(const SettingsScreen());
                                },
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      // Scales the whole scene down on short screens instead of overflowing.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: wide
                            ? Row(mainAxisSize: MainAxisSize.min, children: [
                                Column(mainAxisSize: MainAxisSize.min, children: [title, const SizedBox(height: 8), lolo]),
                                const SizedBox(width: 48),
                                buttons,
                              ])
                            : Column(mainAxisSize: MainAxisSize.min, children: [
                                title,
                                const SizedBox(height: 18),
                                lolo,
                                const SizedBox(height: 22),
                                buttons,
                              ]),
                      ),
                    ),
                  ),
                ]);
              }),
            ),
          ]);
        },
      ),
    );
  }
}

class _Island extends StatelessWidget {
  const _Island();
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 420,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(200), bottom: Radius.circular(120)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9BE15D), Color(0xFF5CB85C)],
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 20))],
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Text(text, style: CL.text(20)),
      ),
    );
  }
}

class _GiftButton extends StatefulWidget {
  const _GiftButton({required this.available, required this.onTap});
  final bool available;
  final VoidCallback onTap;
  @override
  State<_GiftButton> createState() => _GiftButtonState();
}

class _GiftButtonState extends State<_GiftButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final wob = widget.available ? (1 + 0.08 * (1 - (2 * _c.value - 1).abs())) : 1.0;
        return Transform.scale(scale: wob, child: child);
      },
      child: Stack(clipBehavior: Clip.none, children: [
        RoundButton(icon: Icons.card_giftcard_rounded, size: 54,
            iconColor: const Color(0xFFE53935), onTap: widget.onTap),
        if (widget.available)
          Positioned(
            right: -2, top: -2,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(color: const Color(0xFFE53935), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3)),
            ),
          ),
      ]),
    );
  }
}
