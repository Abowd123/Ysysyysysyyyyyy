import 'package:flutter/material.dart';

import '../../core/crash_guard.dart';
import '../../core/l10n.dart';
import '../../core/progress.dart';
import '../../core/settings.dart';
import '../../engine/artwork_storage.dart';
import '../theme.dart';
import '../widgets/bouncy.dart';

/// Parents only (behind the parental gate).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Settings.instance,
      builder: (context, _) {
        final s = S.of(context);
        final st = Settings.instance;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F3EE),
          body: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(children: [
                  RoundButton(icon: Icons.arrow_back_rounded, size: 54, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(child: Text('⚙️ ${s.settings}', style: CL.text(30, weight: 800))),
                ]),
              ),
              Expanded(
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  _Card(children: [
                    _Switch(label: s.sound, icon: Icons.volume_up_rounded, value: st.sound, onChanged: (v) => st.sound = v),
                    _Switch(label: s.music, icon: Icons.music_note_rounded, value: st.music, onChanged: (v) => st.music = v),
                    _Switch(label: s.vibration, icon: Icons.vibration_rounded, value: st.haptics, onChanged: (v) => st.haptics = v),
                  ]),
                  _Card(children: [
                    _Choice<String>(
                      label: s.language, icon: Icons.translate_rounded, value: st.lang,
                      options: const {'ar': 'العربية', 'en': 'English'},
                      onChanged: (v) => st.lang = v,
                    ),
                    _Choice<AgeMode>(
                      label: s.ageMode, icon: Icons.child_care_rounded, value: st.age,
                      options: {AgeMode.little: s.ageLittle, AgeMode.big: s.ageBig},
                      onChanged: (v) => st.age = v,
                    ),
                    _Choice<int>(
                      label: s.timeLimit, icon: Icons.timer_rounded, value: st.timeLimit,
                      options: {0: s.off, 15: s.minutes(15), 30: s.minutes(30), 45: s.minutes(45), 60: s.minutes(60)},
                      onChanged: (v) => st.timeLimit = v,
                    ),
                    _Switch(label: s.unlockAll, icon: Icons.lock_open_rounded, value: st.unlockAll, onChanged: (v) => st.unlockAll = v),
                  ]),
                  _Card(children: [
                    ListTile(
                      leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFE53935)),
                      title: Text(s.resetAll, style: CL.text(18, color: const Color(0xFFE53935))),
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            content: Text(s.resetConfirm, style: CL.text(20)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
                              TextButton(onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(s.yes, style: const TextStyle(color: Color(0xFFE53935)))),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await ArtworkStorage.deleteAll();
                          Progress.instance.reset();
                        }
                      },
                    ),
                  ]),
                  _Card(children: [
                    ListTile(
                      leading: const Icon(Icons.bug_report_rounded, color: Colors.black45),
                      title: Text(s.errorLog, style: CL.text(18, weight: 600)),
                      onTap: () async {
                        final log = await CrashGuard.read();
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(s.errorLog),
                            content: SizedBox(
                              width: 500,
                              height: 360,
                              child: SingleChildScrollView(
                                child: SelectableText(log.isEmpty ? '✅' : log,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                              ),
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.done))],
                          ),
                        );
                      },
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('🔒 ${s.privacy}', textAlign: TextAlign.center,
                        style: CL.text(16, weight: 500, color: Colors.black54)),
                  ),
                  Center(child: Text('ColorLand 1.0.0', style: CL.text(14, weight: 500, color: Colors.black38))),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(children: children),
      );
}

class _Switch extends StatelessWidget {
  const _Switch({required this.label, required this.icon, required this.value, required this.onChanged});
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: Icon(icon, color: CL.primary),
        title: Text(label, style: CL.text(19, weight: 600)),
        value: value,
        activeColor: CL.primary,
        onChanged: onChanged,
      );
}

class _Choice<T> extends StatelessWidget {
  const _Choice({required this.label, required this.icon, required this.value, required this.options, required this.onChanged});
  final String label;
  final IconData icon;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: CL.primary),
            const SizedBox(width: 16),
            Text(label, style: CL.text(19, weight: 600)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in options.entries)
              ChoiceChip(
                label: Text(e.value, style: CL.text(16, weight: 600,
                    color: e.key == value ? Colors.white : CL.ink)),
                selected: e.key == value,
                selectedColor: CL.primary,
                onSelected: (_) => onChanged(e.key),
              ),
          ]),
        ]),
      );
}
