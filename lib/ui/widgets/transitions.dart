import 'package:flutter/material.dart';

/// Playful "pop" page transition: scale up from 0.92 with fade.
Route<T> popRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a, b) => page,
      transitionsBuilder: (context, a, b, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
