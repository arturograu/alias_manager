import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton._({
    super.key,
    required this.onPressed,
    this.icon,
    required this.child,
  });

  const AppButton.icon({
    Key? key,
    required VoidCallback onPressed,
    required IconData icon,
    required Widget child,
  }) : this._(key: key, onPressed: onPressed, icon: icon, child: child);

  final VoidCallback onPressed;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconButton = icon;

    if (iconButton != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
      child: child,
    );
  }
}
