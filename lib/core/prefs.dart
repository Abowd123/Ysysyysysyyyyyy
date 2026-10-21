import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences that never takes the app down.
/// If the platform store fails (e.g. a broken plugin in a release build),
/// the app keeps running on an in-memory store for this session.
class Prefs {
  static SharedPreferences? _cached;
  static bool usingFallback = false;
  static Object? lastError;

  static Future<SharedPreferences> get() async {
    if (_cached != null) return _cached!;
    try {
      return _cached = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('SharedPreferences unavailable, using memory: $e');
      lastError = e;
      usingFallback = true;
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      return _cached = await SharedPreferences.getInstance();
    }
  }
}
