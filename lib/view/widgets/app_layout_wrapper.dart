import 'package:alias_manager/view/app_theme.dart';
import 'package:flutter/material.dart';

const _kMaxWidth = 1200.0;

class AppLayoutWrapper extends StatelessWidget {
  const AppLayoutWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxWidth),
          child: child,
        ),
      ),
    );
  }
}
