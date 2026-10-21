import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/catalog.dart';
import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../core/settings.dart';
import '../../effects/particle_layer.dart';
import '../../effects/particles.dart';
import '../../effects/sfx.dart';
import '../../engine/artwork_storage.dart';
import '../../engine/coloring_canvas.dart';
import '../../engine/coloring_controller.dart';
import '../../engine/coloring_document.dart';
import '../theme.dart';
import '../widgets/backdrop.dart';
import '../widgets/bouncy.dart';
import '../widgets/lolo.dart';
import '../widgets/mix_sheet.dart';
import '../widgets/transitions.dart';
import 'living_screen.dart';

class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key, required DrawingMeta this.meta, this.mode = ColoringMode.classic})
      : freeId = null;

  /// Blank page. Pass [id] to continue an existing free drawing.
  ColoringScreen.free({super.key, String? id})
      : meta = null,
        mode = ColoringMode.free,
        freeId = id ?? 'free_${DateTime.now().millisecondsSinceEpoch}';

  /// Opens any saved artwork from the gallery.
  static Widget resume(String id) {
    if (Catalog.isFreeId(id)) return ColoringScreen.free(id: id);
    final m = Catalog.instance.drawing(id);
    if (m == null) return ColoringScreen.free();
    return ColoringScreen(meta: m);
  }

  final DrawingMeta? meta;
  final ColoringMode mode;
  final String? freeId;

  String get drawingId => meta?.id ?? freeId!;

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  ColoringController? _controller;
  final GlobalKey<ColoringCanvasState> _canvasKey = GlobalKey();
  final GlobalKey<LoloState> _lolo = GlobalKey();
  final ParticleSystem _confetti = ParticleSystem();
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Timer? _saveTimer;
  DocState? _savedState;
  bool _celebrating = false;
  bool _wasNew = false;
  Timer? _celebrateTimer;
  LoloMood _mood = LoloMood.idle;
  Timer? _moodTimer;

  bool get _little => Settings.instance.age == AgeMode.little;
  bool get _free => widget.mode == ColoringMode.free;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final w = widget.meta == null ? null : Catalog.instance.world(widget.meta!.world);
    if (w != null) SoundFx.instance.music(w.music);
    _load();
  }

  Future<void> _load() async {
    final drawingFuture = Catalog.instance.svgFor(widget.drawingId);
    final savedFuture = ArtworkStorage.load(widget.drawingId);
    final drawing = await drawingFuture;
    final saved = await savedFuture;
    if (!mounted) return;
    _wasNew = saved == null;
    final c = ColoringController(
      drawing: drawing,
      meta: widget.meta,
      mode: widget.mode,
      paperColor: _free ? Colors.white : CL.paper,
    );
    if (saved != null) c.restore(saved);
    if (_little && !_free && widget.mode == ColoringMode.classic) c.brushSize = 48;
    _savedState = c.state;
    c.addListener(_scheduleSave);
    setState(() => _controller = c);
  }

  // ------------------------------------------------------------ autosave
  void _scheduleSave() {
    final c = _controller;
    if (c == null || identical(c.state, _savedState)) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  Future<void> _saveNow() async {
    final c = _controller;
    if (c == null || identical(c.state, _savedState)) return;
    final s = c.state;
    _savedState = s;
    if (_free && !c.hasContent) {
      await ArtworkStorage.delete(widget.drawingId);
      return;
    }
    await ArtworkStorage.save(widget.drawingId, s);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveTimer?.cancel();
      _saveNow();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _celebrateTimer?.cancel();
    _moodTimer?.cancel();
    final c = _controller;
    if (c != null && _free && _wasNew && c.hasContent) {
      Progress.instance.registerFreeDrawing();
    }
    _saveNow();
    c?.removeListener(_scheduleSave);
    c?.dispose();
    _confetti.dispose();
    _shake.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------- effects
  void _setMood(LoloMood m, {int ms = 1200}) {
    setState(() => _mood = m);
    _moodTimer?.cancel();
    _moodTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _mood = LoloMood.idle);
    });
  }

  void _haptic(void Function() f) {
    if (Settings.instance.haptics) f();
  }

  void _onEffect(EffectEvent e) {
    final sfx = SoundFx.instance;
    switch (e.kind) {
      case EffectKind.fill:
        sfx.play(Sfx.pop);
        _haptic(HapticFeedback.lightImpact);
        if (_mood != LoloMood.happy) _setMood(LoloMood.happy, ms: 700);
      case EffectKind.magicReveal:
        sfx.play(Sfx.sparkle, volume: 0.7);
        _haptic(HapticFeedback.lightImpact);
        _setMood(LoloMood.happy, ms: 700);
      case EffectKind.wand:
        sfx.play(Sfx.magic);
        _haptic(HapticFeedback.mediumImpact);
        _setMood(LoloMood.cheer);
      case EffectKind.strokeStart:
        sfx.play(Sfx.swish, volume: 0.25);
      case EffectKind.undo:
      case EffectKind.redo:
        sfx.play(Sfx.undo, volume: 0.6);
      case EffectKind.completed:
        _celebrate();
      case EffectKind.wrong:
        sfx.play(Sfx.wrong, volume: 0.5);
        _shake.forward(from: 0);
        _setMood(LoloMood.think);
      case EffectKind.nothing:
        sfx.play(Sfx.click, volume: 0.3);
      case EffectKind.strokeEnd:
        break;
    }
  }

  void _celebrate() {
    final earned = Progress.instance.completeDrawing(widget.drawingId);
    SoundFx.instance.play(Sfx.tada);
    Future.delayed(const Duration(milliseconds: 350), () => SoundFx.instance.play(Sfx.sparkle, volume: 0.7));
    if (earned > 0) {
      Future.delayed(const Duration(milliseconds: 900), () => SoundFx.instance.play(Sfx.star));
    }
    _haptic(HapticFeedback.mediumImpact);
    _confetti.confetti(MediaQuery.sizeOf(context));
    _setMood(LoloMood.cheer, ms: 3000);
    setState(() => _celebrating = true);
    _celebrateTimer?.cancel();
    _celebrateTimer = Timer(const Duration(milliseconds: 4200), () {
      if (mounted) setState(() => _celebrating = false);
    });
  }

  Future<void> _bringToLife() async {
    final c = _controller;
    if (c == null) return;
    setState(() => _celebrating = false);
    await _saveNow();
    if (!mounted) return;
    await Navigator.of(context).push(popRoute(LivingScreen(
      drawing: c.drawing,
      meta: widget.meta,
      state: c.state,
    )));
  }

  // ----------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final w = widget.meta == null ? null : Catalog.instance.world(widget.meta!.world);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Backdrop(
              colors: w == null
                  ? const [Color(0xFFDDF3FF), Color(0xFFFFE8F0)]
                  : [CL.lighter(w.colors.first, 0.14), CL.lighter(w.colors.last, 0.2)],
              floaters: const ['☁️', '✨'],
            ),
          ),
          SafeArea(
            child: c == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 7, color: CL.primary))
                : LayoutBuilder(builder: (context, box) {
                    final landscape = box.maxWidth > box.maxHeight * 1.15;
                    return landscape ? _landscape(c) : _portrait(c);
                  }),
          ),
          Positioned.fill(child: ParticleLayer(system: _confetti)),
          if (_celebrating && c != null)
            Positioned.fill(
              child: _CelebrateOverlay(
                canLive: !_free,
                onLive: _bringToLife,
                onClose: () => setState(() => _celebrating = false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _portrait(ColoringController c) => Column(
        children: [
          _TopBar(controller: c, title: _title, canvasKey: _canvasKey, onLive: _free ? null : _bringToLife),
          Expanded(child: _canvasCard(c)),
          const SizedBox(height: 6),
          _ToolRow(controller: c, little: _little),
          const SizedBox(height: 8),
          SizedBox(height: 78, child: _Palette(controller: c, axis: Axis.horizontal, little: _little)),
          const SizedBox(height: 10),
        ],
      );

  Widget _landscape(ColoringController c) => Row(
        children: [
          Expanded(
            child: Column(children: [
              _TopBar(controller: c, title: _title, canvasKey: _canvasKey, onLive: _free ? null : _bringToLife),
              Expanded(child: _canvasCard(c)),
            ]),
          ),
          SizedBox(
            width: 280,
            child: Column(children: [
              const SizedBox(height: 12),
              _ToolRow(controller: c, little: _little),
              const SizedBox(height: 8),
              Expanded(child: _Palette(controller: c, axis: Axis.vertical, little: _little)),
            ]),
          ),
        ],
      );

  String get _title {
    final s = S.of(context);
    final m = widget.meta;
    if (m == null) return s.freeDraw;
    final mode = switch (widget.mode) {
      ColoringMode.magic => ' ✨',
      ColoringMode.numbers => ' 🔢',
      _ => '',
    };
    return '${m.titleFor(s.lang)}$mode';
  }

  Widget _canvasCard(ColoringController c) {
    final aspect = c.drawing.size.width / c.drawing.size.height;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Center(
        child: AspectRatio(
          aspectRatio: aspect,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final v = _shake.value;
                  final dx = _shake.isAnimating ? 12 * (1 - v) * ((v * 12).floor().isEven ? 1 : -1) : 0.0;
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: [
                      const BoxShadow(color: Color(0xFFE6D6C6), offset: Offset(0, 8)),
                      BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 28, offset: const Offset(0, 16)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: ColoringCanvas(key: _canvasKey, controller: c, onEffect: _onEffect),
                    ),
                  ),
                ),
              ),
            ),
            // Lolo peeks from the corner and reacts.
            Positioned(
              left: -6,
              bottom: -14,
              child: IgnorePointer(
                ignoring: false,
                child: ListenableBuilder(
                  listenable: c,
                  builder: (context, _) => Lolo(
                    key: _lolo,
                    size: 86,
                    mood: _mood,
                    beret: c.tool == Tool.eraser ? const Color(0xFFBDBDBD) : c.color,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ======================================================================
class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller, required this.title, required this.canvasKey, this.onLive});
  final ColoringController controller;
  final String title;
  final GlobalKey<ColoringCanvasState> canvasKey;
  final VoidCallback? onLive;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Row(
          children: [
            RoundButton(icon: Icons.arrow_back_rounded, size: 50, onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 10),
            Expanded(child: _ProgressPill(controller: controller, title: title)),
            const SizedBox(width: 8),
            if (onLive != null && controller.isCompleted) ...[
              _PulsingLive(onTap: onLive!),
              const SizedBox(width: 8),
            ],
            RoundButton(icon: Icons.undo_rounded, size: 46, onTap: controller.canUndo ? controller.undo : null),
            const SizedBox(width: 8),
            RoundButton(icon: Icons.redo_rounded, size: 46, onTap: controller.canRedo ? controller.redo : null),
            const SizedBox(width: 8),
            RoundButton(icon: Icons.zoom_out_map_rounded, size: 46, onTap: () => canvasKey.currentState?.resetView()),
          ],
        ),
      ),
    );
  }
}

class _PulsingLive extends StatefulWidget {
  const _PulsingLive({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_PulsingLive> createState() => _PulsingLiveState();
}

class _PulsingLiveState extends State<_PulsingLive> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: RoundButton(
          icon: Icons.auto_awesome_rounded, size: 54,
          color: const Color(0xFFA66CFF), iconColor: Colors.white, onTap: widget.onTap),
      );
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.controller, required this.title});
  final ColoringController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    final free = controller.mode == ColoringMode.free;
    return LayoutBuilder(builder: (context, box) {
      // On narrow phones the title hides and only the progress bar stays.
      final showTitle = box.maxWidth > 150 || free;
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0xFFE6D6C6), offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            if (box.maxWidth > 70)
              Icon(free ? Icons.brush_rounded : Icons.star_rounded,
                  color: free ? const Color(0xFF3EC1D3) : const Color(0xFFFFC93C), size: 28),
            if (showTitle) ...[
              const SizedBox(width: 6),
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1, style: CL.text(19))),
            ],
            if (!free) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: controller.progress),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: const Color(0xFFF1E9DF),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF7BC86C)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.controller, required this.little});
  final ColoringController controller;
  final bool little;

  static const _styleIcons = {
    BrushStyle.normal: ('🖌️', Color(0xFFFFF1E6)),
    BrushStyle.crayon: ('🖍️', Color(0xFFFFF1E6)),
    BrushStyle.watercolor: ('💧', Color(0xFFE6F5FF)),
    BrushStyle.neon: ('💡', Color(0xFF2B2D6E)),
    BrushStyle.glitter: ('✨', Color(0xFFFFF7D6)),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final t = c.tool;
        final mode = c.mode;
        final showSizes = t == Tool.brush || t == Tool.eraser;
        final sizes = little ? const [48.0, 80.0] : CL.brushSizes;
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            if (mode != ColoringMode.magic)
              RoundButton(icon: Icons.format_color_fill_rounded, selected: t == Tool.fill,
                  onTap: () => c.tool = Tool.fill),
            if (mode != ColoringMode.numbers)
              RoundButton(icon: mode == ColoringMode.magic ? Icons.auto_fix_normal_rounded : Icons.brush_rounded,
                  selected: t == Tool.brush, onTap: () => c.tool = Tool.brush),
            if (mode == ColoringMode.classic || mode == ColoringMode.magic)
              RoundButton(icon: Icons.auto_fix_high_rounded, selected: t == Tool.wand,
                  color: t == Tool.wand ? CL.primary : const Color(0xFFFFF4C2),
                  iconColor: const Color(0xFFB8860B), onTap: () => c.tool = Tool.wand),
            if (mode == ColoringMode.classic || mode == ColoringMode.free)
              RoundButton(icon: Icons.cleaning_services_rounded, selected: t == Tool.eraser,
                  onTap: () => c.tool = Tool.eraser),
            if (!little && t == Tool.brush && (mode == ColoringMode.classic || mode == ColoringMode.free))
              _Group(children: [
                for (final st in BrushStyle.values)
                  _StyleChip(
                    emoji: _styleIcons[st]!.$1,
                    bg: _styleIcons[st]!.$2,
                    selected: c.style == st,
                    onTap: () => c.style = st,
                  ),
              ]),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: showSizes
                  ? _Group(children: [
                      for (final s in sizes)
                        _SizeDot(
                          docSize: s,
                          color: t == Tool.eraser ? const Color(0xFFBDBDBD) : (mode == ColoringMode.magic ? const Color(0xFFA66CFF) : c.color),
                          selected: c.brushSize == s,
                          onTap: () => c.brushSize = s,
                        ),
                    ])
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      );
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({required this.emoji, required this.bg, required this.selected, required this.onTap});
  final String emoji;
  final Color bg;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46, height: 46,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: selected ? CL.primary : Colors.transparent, width: 3),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      );
}

class _SizeDot extends StatelessWidget {
  const _SizeDot({required this.docSize, required this.color, required this.selected, required this.onTap});
  final double docSize;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = 8 + docSize * 0.3;
    return Bouncy(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFFFFF1E6) : Colors.transparent,
          border: Border.all(color: selected ? CL.primary : Colors.transparent, width: 3),
        ),
        child: Container(
          width: d, height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: CL.darker(color, 0.15), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette({required this.controller, required this.axis, required this.little});
  final ColoringController controller;
  final Axis axis;
  final bool little;

  static const _littlePalette = [
    Color(0xFFE53935), Color(0xFFFF9F1C), Color(0xFFFFD23F), Color(0xFF43A047),
    Color(0xFF4FC3F7), Color(0xFF1E88E5), Color(0xFFA66CFF), Color(0xFFFF8FB1),
    Color(0xFF8D6E63), Color(0xFFFFFFFF), Color(0xFF37474F),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, Progress.instance]),
      builder: (context, _) {
        final c = controller;
        if (c.mode == ColoringMode.magic) {
          return Center(
            child: Text('✨ 👆 ✨', style: CL.text(34)),
          );
        }
        final numbers = c.mode == ColoringMode.numbers;
        final colors = numbers
            ? c.meta!.palette
            : [
                ...(little ? _littlePalette : CL.palette),
                for (final m in Progress.instance.mixedColors) Color(m),
              ];
        final items = <Widget>[
          if (!numbers && !little)
            _MixButton(onTap: () async {
              final col = await showMixSheet(context);
              if (col != null) {
                Progress.instance.addMixedColor(col.toARGB32());
                c.color = col;
                SoundFx.instance.play(Sfx.unlock, volume: 0.6);
              }
            }),
          for (var i = 0; i < colors.length; i++)
            _Swatch(
              color: colors[i],
              number: numbers ? i + 1 : null,
              selected: c.color == colors[i] && c.tool != Tool.eraser && c.tool != Tool.wand,
              onTap: () {
                c.color = colors[i];
                SoundFx.instance.play(Sfx.click, volume: 0.4);
              },
            ),
        ];
        if (axis == Axis.horizontal) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [for (final w in items) Padding(padding: const EdgeInsets.all(5), child: w)],
          );
        }
        return GridView.count(
          crossAxisCount: 4,
          padding: const EdgeInsets.all(12),
          children: [for (final w in items) Center(child: w)],
        );
      },
    );
  }
}

class _MixButton extends StatelessWidget {
  const _MixButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: Container(
          width: 54, height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(colors: [
              Color(0xFFE53935), Color(0xFFFFD23F), Color(0xFF43A047),
              Color(0xFF1E88E5), Color(0xFFA66CFF), Color(0xFFE53935),
            ]),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 4))],
          ),
          child: const Text('🧪', style: TextStyle(fontSize: 24)),
        ),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap, this.number});
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final int? number;

  @override
  Widget build(BuildContext context) {
    final light = color.computeLuminance() > 0.6;
    return Bouncy(
      onTap: onTap,
      sound: false,
      child: AnimatedScale(
        scale: selected ? 1.18 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: Container(
          width: 54, height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.5),
              radius: 0.9,
              colors: [CL.lighter(color, 0.16), color, CL.darker(color, 0.06)],
              stops: const [0, 0.6, 1],
            ),
            border: Border.all(
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7), width: selected ? 5 : 3),
            boxShadow: [
              BoxShadow(color: CL.darker(color, 0.22), offset: const Offset(0, 4)),
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.25 : 0.1),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: number != null
              ? Text('$number', style: CL.text(24, color: light ? CL.ink : Colors.white, weight: 800))
              : (selected ? Icon(Icons.check_rounded, color: light ? CL.ink : Colors.white, size: 26) : null),
        ),
      ),
    );
  }
}

class _CelebrateOverlay extends StatelessWidget {
  const _CelebrateOverlay({required this.canLive, required this.onLive, required this.onClose});
  final bool canLive;
  final VoidCallback onLive;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        alignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFFFC93C), width: 5),
              boxShadow: [
                const BoxShadow(color: Color(0xFFE0A800), offset: Offset(0, 8)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 14)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 44),
                Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 60),
                Icon(Icons.star_rounded, color: Color(0xFFFFC93C), size: 44),
              ]),
              Text(s.wellDone, style: CL.text(40, color: CL.primary, weight: 800)),
              Text(s.finished, style: CL.text(24)),
              if (canLive) ...[
                const SizedBox(height: 16),
                PillButton(label: s.bringToLife, emoji: '✨', color: const Color(0xFFA66CFF), onTap: onLive),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
