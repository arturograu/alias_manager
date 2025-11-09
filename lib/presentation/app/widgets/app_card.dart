import 'package:alias_manager/presentation/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = 16});

  final double padding;
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
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}
