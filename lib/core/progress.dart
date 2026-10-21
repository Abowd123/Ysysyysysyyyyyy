import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs.dart';

import 'catalog.dart';

class Achievement {
  const Achievement(this.id, this.emoji, this.ar, this.en, this.test);
  final String id;
  final String emoji;
  final String ar;
  final String en;
  final bool Function(Progress p) test;

  String titleFor(String lang) => lang == 'en' ? en : ar;
}

/// Stars, completed / alive drawings, badges, daily gift and streak.
/// Small enough to live in SharedPreferences as one JSON blob; drawings
/// themselves are saved separately (ArtworkStorage).
class Progress extends ChangeNotifier {
  Progress._(this._p) {
    _read();
  }
  static late Progress instance;
  final SharedPreferences _p;
  static const _key = 'progress_v1';

  int stars = 0;
  final Set<String> completed = {};
  final Set<String> alive = {};
  final Set<int> mixedColors = {};
  int freeDrawings = 0;
  String? lastGiftDay;
  String? lastOpenDay;
  int streak = 0;
  final Set<String> badges = {};

  /// Badges unlocked during this session (UI shows a toast).
  final StreamController<Achievement> _newBadges =
      StreamController<Achievement>.broadcast();
  Stream<Achievement> get newBadges => _newBadges.stream;

  static Future<Progress> load() async {
    instance = Progress._(await Prefs.get());
    instance._touchDay();
    return instance;
  }

  @visibleForTesting
  static Progress forTest(SharedPreferences p) => Progress._(p);

  void _read() {
    final raw = _p.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      stars = j['stars'] as int? ?? 0;
      completed.addAll(((j['completed'] as List?) ?? const []).cast<String>());
      alive.addAll(((j['alive'] as List?) ?? const []).cast<String>());
      mixedColors.addAll(((j['mixed'] as List?) ?? const []).cast<int>());
      freeDrawings = j['free'] as int? ?? 0;
      lastGiftDay = j['gift'] as String?;
      lastOpenDay = j['open'] as String?;
      streak = j['streak'] as int? ?? 0;
      badges.addAll(((j['badges'] as List?) ?? const []).cast<String>());
    } catch (e) {
      debugPrint('progress reset: $e');
    }
  }

  void _save() {
    _p.setString(
      _key,
      jsonEncode({
        'stars': stars,
        'completed': completed.toList(),
        'alive': alive.toList(),
        'mixed': mixedColors.toList(),
        'free': freeDrawings,
        'gift': lastGiftDay,
        'open': lastOpenDay,
        'streak': streak,
        'badges': badges.toList(),
      }),
    );
  }

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _touchDay([DateTime? now]) {
    final today = dayKey(now ?? DateTime.now());
    if (lastOpenDay == today) return;
    final yesterday =
        dayKey((now ?? DateTime.now()).subtract(const Duration(days: 1)));
    streak = lastOpenDay == yesterday ? streak + 1 : 1;
    lastOpenDay = today;
    _changed();
  }

  // ------------------------------------------------------------- events
  /// Returns stars earned (0 if this drawing was already completed).
  int completeDrawing(String id) {
    if (completed.contains(id)) return 0;
    completed.add(id);
    stars += 1;
    _changed();
    return 1;
  }

  int bringToLife(String id) {
    if (alive.contains(id)) return 0;
    alive.add(id);
    stars += 1;
    _changed();
    return 1;
  }

  void addMixedColor(int argb) {
    if (mixedColors.add(argb)) _changed();
  }

  void registerFreeDrawing() {
    freeDrawings++;
    _changed();
  }

  bool get giftAvailable => lastGiftDay != dayKey(DateTime.now());

  /// Daily gift: 2 stars, once per calendar day.
  int claimGift() {
    if (!giftAvailable) return 0;
    lastGiftDay = dayKey(DateTime.now());
    stars += 2;
    _changed();
    return 2;
  }

  bool worldUnlocked(WorldMeta w, {bool unlockAll = false}) =>
      unlockAll || stars >= w.starsNeeded;

  int completedIn(String world, Catalog c) =>
      c.drawingsIn(world).where((d) => completed.contains(d.id)).length;

  /// Parents: wipe everything.
  void reset() {
    stars = 0;
    completed.clear();
    alive.clear();
    mixedColors.clear();
    freeDrawings = 0;
    badges.clear();
    lastGiftDay = null;
    _save();
    notifyListeners();
  }

  void _changed() {
    _checkBadges();
    _save();
    notifyListeners();
  }

  void _checkBadges() {
    for (final a in achievements) {
      if (!badges.contains(a.id) && a.test(this)) {
        badges.add(a.id);
        _newBadges.add(a);
      }
    }
  }

  static bool _worldDone(Progress p, String world) {
    final c = Catalog.maybeInstance;
    if (c == null) return false;
    final ds = c.drawingsIn(world);
    return ds.isNotEmpty && ds.every((d) => p.completed.contains(d.id));
  }

  static final List<Achievement> achievements = [
    Achievement('first', '🎨', 'أول رسمة', 'First Drawing', (p) => p.completed.isNotEmpty),
    Achievement('five', '🖍️', 'خمس رسومات', 'Five Drawings', (p) => p.completed.length >= 5),
    Achievement('ten', '🏅', 'فنان صغير: 10 رسومات', 'Little Artist: 10', (p) => p.completed.length >= 10),
    Achievement('all', '👑', 'كل الرسومات', 'Every Drawing', (p) {
      final c = Catalog.maybeInstance;
      return c != null && p.completed.length >= c.drawings.length;
    }),
    Achievement('life1', '✨', 'أول رسمة حيّة', 'First Alive', (p) => p.alive.isNotEmpty),
    Achievement('life5', '🪄', 'ساحر الرسومات', 'Drawing Wizard', (p) => p.alive.length >= 5),
    Achievement('mix1', '🧪', 'مكتشف الألوان', 'Color Explorer', (p) => p.mixedColors.isNotEmpty),
    Achievement('mix5', '🌈', 'عالم الألوان', 'Color Scientist', (p) => p.mixedColors.length >= 5),
    Achievement('free3', '✏️', 'رسام حر', 'Free Artist', (p) => p.freeDrawings >= 3),
    Achievement('streak3', '🔥', '3 أيام متتالية', '3 Days in a Row', (p) => p.streak >= 3),
    Achievement('streak7', '🏆', 'أسبوع كامل', 'A Whole Week', (p) => p.streak >= 7),
    Achievement('stars20', '⭐', '20 نجمة', '20 Stars', (p) => p.stars >= 20),
    Achievement('animals', '🦁', 'صديق الحيوانات', 'Animal Friend', (p) => _worldDone(p, 'animals')),
    Achievement('sea', '🐠', 'فنان البحار', 'Sea Artist', (p) => _worldDone(p, 'sea')),
    Achievement('space', '🚀', 'بطل الفضاء', 'Space Hero', (p) => _worldDone(p, 'space')),
  ];
}
