import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../effects/sfx.dart';
import '../theme.dart';
import 'bouncy.dart';

/// Parental gate: the number is written in WORDS so pre-readers can't pass.
/// Returns true when solved.
Future<bool> showParentalGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _Gate(),
  );
  return ok ?? false;
}

class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  final math.Random _rnd = math.Random();
  /// Two numbers in order: a guessing child has a 1-in-72 chance, not 1-in-9.
  late List<int> _targets;
  int _step = 0;
  late List<int> _options;
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _roll();
  }

  void _roll() {
    final a = 1 + _rnd.nextInt(9);
    var b = 1 + _rnd.nextInt(9);
    while (b == a) {
      b = 1 + _rnd.nextInt(9);
    }
    _targets = [a, b];
    _step = 0;
    _options = List.generate(9, (i) => i + 1)..shuffle(_rnd);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.lock_rounded, size: 46, color: CL.primary),
          const SizedBox(height: 6),
          Text(s.parents, style: CL.text(26)),
          const SizedBox(height: 8),
          Text(s.gateQuestion2(s.numberWord(_targets[0]), s.numberWord(_targets[1])),
              textAlign: TextAlign.center, style: CL.text(22, weight: 600)),
          const SizedBox(height: 8),
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 2; i++)
              Container(
                width: 16, height: 16, margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _step ? CL.primary : const Color(0xFFE0D6CC),
                ),
              ),
          ]),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final n in _options)
                Bouncy(
                  onTap: () {
                    if (n == _targets[_step]) {
                      if (_step == 1) {
                        Navigator.pop(context, true);
                      } else {
                        setState(() => _step = 1);
                      }
                    } else {
                      SoundFx.instance.play(Sfx.wrong);
                      setState(() {
                        _tries++;
                        _roll();
                      });
                      if (_tries >= 3) Navigator.pop(context, false);
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFD0B8), width: 3),
                    ),
                    child: Text('$n', style: CL.text(30)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel, style: CL.text(18, color: Colors.grey)),
          ),
        ]),
      ),
    );
  }
}
