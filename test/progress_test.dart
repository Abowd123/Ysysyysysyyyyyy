import 'package:colorland/core/catalog.dart';
import 'package:colorland/core/progress.dart';
import 'package:colorland/core/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Progress p;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    p = Progress.forTest(await SharedPreferences.getInstance());
  });

  test('a drawing gives a star once, bringing it to life gives one more', () {
    expect(p.completeDrawing('lion_01'), 1);
    expect(p.completeDrawing('lion_01'), 0);
    expect(p.bringToLife('lion_01'), 1);
    expect(p.bringToLife('lion_01'), 0);
    expect(p.stars, 2);
  });

  test('daily gift once per day', () {
    expect(p.giftAvailable, isTrue);
    expect(p.claimGift(), 2);
    expect(p.giftAvailable, isFalse);
    expect(p.claimGift(), 0);
  });

  test('first badge is announced exactly once', () async {
    final got = <String>[];
    final sub = p.newBadges.listen((a) => got.add(a.id));
    p.completeDrawing('lion_01');
    p.completeDrawing('cat_01');
    await Future<void>.delayed(Duration.zero);
    expect(got.where((id) => id == 'first').length, 1);
    await sub.cancel();
  });

  test('worlds unlock with stars', () {
    final w = WorldMeta(id: 'sea', emoji: '🌊', title: const {'ar': 'بحر'}, colors: const [], starsNeeded: 3, music: 'm');
    expect(p.worldUnlocked(w), isFalse);
    p.claimGift();
    p.completeDrawing('lion_01');
    expect(p.worldUnlocked(w), isTrue);
    expect(p.worldUnlocked(w.copyLocked(), unlockAll: true), isTrue);
  });

  test('daily play time persists across restarts', () async {
    final st = await Settings.load();
    st.addUsage(600);
    final again = await Settings.load();
    expect(again.usedToday, 600);
    again.resetUsage();
    expect(again.usedToday, 0);
  });

  test('parents reset wipes progress', () {
    p.completeDrawing('lion_01');
    p.reset();
    expect(p.stars, 0);
    expect(p.completed, isEmpty);
  });

  test('progress survives a restart', () async {
    p.completeDrawing('lion_01');
    final again = Progress.forTest(await SharedPreferences.getInstance());
    expect(again.completed, contains('lion_01'));
    expect(again.stars, 1);
  });
}

extension on WorldMeta {
  WorldMeta copyLocked() => WorldMeta(
      id: id, emoji: emoji, title: title, colors: colors, starsNeeded: 999, music: music);
}
