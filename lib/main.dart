import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/catalog.dart';
import 'core/crash_guard.dart';
import 'core/l10n.dart';
import 'core/progress.dart';
import 'core/settings.dart';
import 'effects/sfx.dart';
import 'engine/brushes.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/rest_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets/lolo.dart';

Future<void> main() => CrashGuard.run(() async {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      runApp(const ColorLandApp());
    });

class ColorLandApp extends StatefulWidget {
  const ColorLandApp({super.key});
  @override
  State<ColorLandApp> createState() => _ColorLandAppState();
}

class _ColorLandAppState extends State<ColorLandApp> with WidgetsBindingObserver {
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final _navigator = GlobalKey<NavigatorState>();
  late final Future<void> _boot = _init();
  StreamSubscription<Achievement>? _badgeSub;
  Timer? _usageTimer;
  bool _resting = false;

  Future<void> _init() async {
    final started = DateTime.now();
    await Settings.load();
    await Progress.load();
    await Catalog.load();
    TextureBank.init();
    unawaited(SoundFx.instance.init());
    _badgeSub = Progress.instance.newBadges.listen(_showBadge);
    WidgetsBinding.instance.addObserver(this);
    _usageTimer = Timer.periodic(const Duration(seconds: 15), (_) => _tickUsage());
    // Let the splash breathe for a moment so Lolo can say hi.
    final wait = const Duration(milliseconds: 1200) - DateTime.now().difference(started);
    if (!wait.isNegative) await Future.delayed(wait);
  }

  @override
  void dispose() {
    _badgeSub?.cancel();
    _usageTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) SoundFx.instance.pauseAll();
    if (state == AppLifecycleState.resumed) SoundFx.instance.resumeAll();
  }

  void _tickUsage() {
    final st = Settings.instance;
    final limit = st.timeLimit;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    if (_resting) return;
    st.addUsage(15);
    if (limit > 0 && st.usedToday >= limit * 60) {
      _resting = true;
      SoundFx.instance.pauseAll();
      _navigator.currentState?.push(MaterialPageRoute(
        builder: (_) => RestScreen(onContinue: () {
          _resting = false;
          st.resetUsage();
          SoundFx.instance.resumeAll();
          _navigator.currentState?.pop();
        }),
      ));
    }
  }

  void _showBadge(Achievement a) {
    SoundFx.instance.play(Sfx.achievement);
    _messenger.currentState?.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      elevation: 10,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFFFC93C), width: 4),
      ),
      content: Row(children: [
        Text(a.emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.current.newBadge, style: CL.text(16, color: CL.primary)),
            Text(a.titleFor(Settings.instance.lang), style: CL.text(22)),
          ]),
        ),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Splash();
        }
        if (snap.hasError) {
          return MaterialApp(home: Scaffold(body: Center(child: Text('Error: ${snap.error}'))));
        }
        return ListenableBuilder(
          listenable: Settings.instance,
          builder: (context, _) {
            final lang = Settings.instance.lang;
            return MaterialApp(
              title: 'ColorLand',
              debugShowCheckedModeBanner: false,
              navigatorKey: _navigator,
              scaffoldMessengerKey: _messenger,
              locale: Locale(lang),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Baloo',
                colorScheme: ColorScheme.fromSeed(seedColor: CL.primary),
                scaffoldBackgroundColor: CL.sky,
              ),
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: Color(0xFFFFB37A),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Lolo(size: 200, mood: LoloMood.happy, interactive: false),
            SizedBox(height: 16),
            Text('ColorLand',
                textDirection: TextDirection.ltr,
                style: TextStyle(fontFamily: 'Baloo', fontSize: 44, color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}
