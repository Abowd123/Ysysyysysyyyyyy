import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

enum Sfx {
  pop, sparkle, tada, click, undo, swish, wrong, magic, unlock, gift, star,
  life, achievement, giggle, hello,
}

/// Low-latency sound effects + looping background music.
/// Audio failures never break the app.
class SoundFx {
  SoundFx._();
  static final SoundFx instance = SoundFx._();

  final Map<String, AudioSource> _sources = {};
  final math.Random _rnd = math.Random();
  bool enabled = true;
  bool _musicEnabled = true;
  bool _ready = false;
  Future<void>? _initFuture;

  String? _musicName;
  SoundHandle? _musicHandle;

  static const Map<Sfx, List<String>> _files = {
    Sfx.pop: ['pop1', 'pop2', 'pop3'],
    Sfx.sparkle: ['sparkle'],
    Sfx.tada: ['tada'],
    Sfx.click: ['click'],
    Sfx.undo: ['undo'],
    Sfx.swish: ['swish'],
    Sfx.wrong: ['wrong'],
    Sfx.magic: ['magic'],
    Sfx.unlock: ['unlock'],
    Sfx.gift: ['gift'],
    Sfx.star: ['star'],
    Sfx.life: ['life'],
    Sfx.achievement: ['achievement'],
    Sfx.giggle: ['giggle'],
    Sfx.hello: ['hello'],
  };

  /// Character voices referenced by drawings (catalog `sound`).
  static const voices = [
    'roar', 'meow', 'chirp', 'beep', 'whoosh', 'toot', 'twinkle', 'bubble',
    'splash', 'launch', 'chime', 'ding', 'squeak', 'boing',
  ];

  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      await SoLoud.instance.init();
      final names = {
        for (final l in _files.values) ...l,
        ...voices,
      };
      for (final n in names) {
        try {
          _sources[n] = await SoLoud.instance.loadAsset('assets/audio/sfx/$n.wav');
        } catch (e) {
          debugPrint('missing sound $n: $e');
        }
      }
      _ready = true;
      if (_musicName != null && _musicEnabled) {
        final n = _musicName!;
        _musicName = null;
        await music(n);
      }
    } catch (e) {
      debugPrint('SoundFx disabled: $e');
    }
  }

  void play(Sfx sfx, {double volume = 0.8}) {
    final list = _files[sfx]!;
    _playName(list[_rnd.nextInt(list.length)], volume);
  }

  /// Plays a character voice by name (e.g. 'roar').
  void voice(String name, {double volume = 0.9}) => _playName(name, volume);

  void _playName(String name, double volume) {
    if (!enabled || !_ready) return;
    final src = _sources[name];
    if (src == null) return;
    _safePlay(src, volume);
  }

  Future<void> _safePlay(AudioSource src, double volume) async {
    try {
      await SoLoud.instance.play(src, volume: volume);
    } catch (e) {
      debugPrint('play failed: $e');
    }
  }

  // ------------------------------------------------------------ music
  bool get musicEnabled => _musicEnabled;
  set musicEnabled(bool v) {
    _musicEnabled = v;
    if (!v) {
      _stopMusic();
    } else if (_musicName != null) {
      final n = _musicName!;
      _musicName = null;
      music(n);
    }
  }

  /// Cross-fades to [name] (asset in assets/audio/music, .ogg). Same track
  /// keeps playing without restarting.
  Future<void> music(String name) async {
    if (_musicName == name && _musicHandle != null) return;
    _musicName = name;
    if (!_ready || !_musicEnabled) return;
    try {
      _stopMusic(keepName: true);
      final key = 'music:$name';
      final src = _sources[key] ??=
          await SoLoud.instance.loadAsset('assets/audio/music/$name.ogg');
      if (_musicName != name) return; // changed while loading
      final h = await SoLoud.instance.play(src, volume: 0, looping: true);
      _musicHandle = h;
      SoLoud.instance.fadeVolume(h, 0.32, const Duration(milliseconds: 900));
    } catch (e) {
      debugPrint('music failed: $e');
    }
  }

  void _stopMusic({bool keepName = true}) {
    final h = _musicHandle;
    _musicHandle = null;
    if (h == null) return;
    try {
      SoLoud.instance.fadeVolume(h, 0, const Duration(milliseconds: 500));
      SoLoud.instance.scheduleStop(h, const Duration(milliseconds: 520));
    } catch (e) {
      debugPrint('stop failed: $e');
    }
    if (!keepName) _musicName = null;
  }

  /// App went to background.
  void pauseAll() {
    final h = _musicHandle;
    if (h == null) return;
    try {
      SoLoud.instance.setPause(h, true);
    } catch (_) {}
  }

  void resumeAll() {
    final h = _musicHandle;
    if (h == null) return;
    try {
      SoLoud.instance.setPause(h, false);
    } catch (_) {}
  }
}
