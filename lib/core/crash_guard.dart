import 'dart:async';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Offline crash safety net: errors are written to a local log file (no
/// internet, nothing leaves the phone) and a broken widget shows a friendly
/// card instead of the red/grey error screen.
class CrashGuard {
  static File? _log;

  static Future<void> run(Future<void> Function() body) async {
    await runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        final dir = await getApplicationDocumentsDirectory();
        _log = File('${dir.path}/crash.log');
      } catch (_) {}
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        _write('flutter', details.exceptionAsString(), details.stack);
      };
      PlatformDispatcher.instance.onError = (e, st) {
        _write('platform', '$e', st);
        return true;
      };
      if (kReleaseMode) {
        ErrorWidget.builder = (details) => const _Oops();
      }
      await body();
    }, (e, st) => _write('zone', '$e', st));
  }

  static void _write(String where, String error, StackTrace? st) {
    debugPrint('[$where] $error');
    final f = _log;
    if (f == null) return;
    try {
      if (f.existsSync() && f.lengthSync() > 200 * 1024) f.deleteSync();
      f.writeAsStringSync(
        '${DateTime.now().toIso8601String()} [$where] $error\n${st ?? ''}\n\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  /// Contents of the local log (shown to parents in settings).
  static Future<String> read() async {
    try {
      final f = _log;
      if (f == null || !await f.exists()) return '';
      return await f.readAsString();
    } catch (_) {
      return '';
    }
  }
}

class _Oops extends StatelessWidget {
  const _Oops();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('🎨💦', style: TextStyle(fontSize: 48), textDirection: TextDirection.ltr),
        ),
      );
}
