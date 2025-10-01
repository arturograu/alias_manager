import 'package:alias_manager/view/app_theme.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(80),
        borderRadius: BorderRadius.circular(ThemeConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurfaceLight.withAlpha(20),
            blurRadius: 10,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
