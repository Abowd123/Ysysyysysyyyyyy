import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../theme.dart';
import '../widgets/lolo.dart';
import '../widgets/parental_gate.dart';

/// Shown when the parent's daily time limit is reached.
class RestScreen extends StatelessWidget {
  const RestScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF2B2D6E), Color(0xFF6C5BB8)]),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🌙', style: TextStyle(fontSize: 70)),
            const Lolo(size: 200, mood: LoloMood.sleep, interactive: false),
            const SizedBox(height: 10),
            Text(s.restTitle, style: CL.text(36, color: Colors.white, weight: 800)),
            Text(s.restBody, style: CL.text(22, color: Colors.white70), textAlign: TextAlign.center),
            const SizedBox(height: 30),
            TextButton.icon(
              onPressed: () async {
                if (await showParentalGate(context)) onContinue();
              },
              icon: const Icon(Icons.lock_rounded, color: Colors.white54),
              label: Text(s.restContinue, style: CL.text(16, color: Colors.white54)),
            ),
          ]),
        ),
      ),
    );
  }
}
