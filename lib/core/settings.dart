import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs.dart';

import '../effects/sfx.dart';

enum AgeMode { little, big }

class Settings extends ChangeNotifier {
  Settings._(this._p);
  static late Settings instance;
  final SharedPreferences _p;

  static Future<Settings> load() async {
    instance = Settings._(await Prefs.get());
    instance._apply();
    return instance;
  }

  bool get sound => _p.getBool('sound') ?? true;
  set sound(bool v) => _set('sound', v);

  bool get music => _p.getBool('music') ?? true;
  set music(bool v) => _set('music', v);

  String get lang => _p.getString('lang') ?? 'ar';
  set lang(String v) {
    _p.setString('lang', v);
    notifyListeners();
  }

  AgeMode get age =>
      (_p.getString('age') ?? 'big') == 'little' ? AgeMode.little : AgeMode.big;
  set age(AgeMode v) {
    _p.setString('age', v == AgeMode.little ? 'little' : 'big');
    notifyListeners();
  }

  bool get unlockAll => _p.getBool('unlockAll') ?? false;
  set unlockAll(bool v) => _set('unlockAll', v);

  /// Daily play limit in minutes; 0 = off.
  int get timeLimit => _p.getInt('timeLimit') ?? 0;
  set timeLimit(int v) {
    _p.setInt('timeLimit', v);
    notifyListeners();
  }

  /// Seconds played today (persists across app restarts, resets each day).
  int get usedToday {
    if (_p.getString('usedDay') != _today()) return 0;
    return _p.getInt('usedSeconds') ?? 0;
  }

  void addUsage(int seconds) {
    final today = _today();
    final base = _p.getString('usedDay') == today ? (_p.getInt('usedSeconds') ?? 0) : 0;
    _p.setString('usedDay', today);
    _p.setInt('usedSeconds', base + seconds);
  }

  /// Parents tapped "continue": give a fresh allowance for today.
  void resetUsage() {
    _p.setString('usedDay', _today());
    _p.setInt('usedSeconds', 0);
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  bool get haptics => _p.getBool('haptics') ?? true;
  set haptics(bool v) => _set('haptics', v);

  void _set(String k, bool v) {
    _p.setBool(k, v);
    _apply();
    notifyListeners();
  }

  void _apply() {
    SoundFx.instance.enabled = sound;
    SoundFx.instance.musicEnabled = music;
  }
}
