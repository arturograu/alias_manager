import 'package:alias_manager/presentation/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppInnerCard extends StatelessWidget {
  const AppInnerCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          ThemeConstants.cardBorderRadius / 1.5,
        ),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
