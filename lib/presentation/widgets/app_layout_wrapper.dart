import 'package:flutter/material.dart';

const _kMaxWidth = 1200.0;

class AppLayoutWrapper extends StatelessWidget {
  const AppLayoutWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxWidth),
          child: child,
        ),
      ),
    );
  }
}
