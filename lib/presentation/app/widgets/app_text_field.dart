import 'package:alias_manager/presentation/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        label: Text(labelText),
        labelStyle: const TextStyle(color: AppColors.onSurface),
        floatingLabelStyle: const TextStyle(color: AppColors.onSurface),
        hintText: hintText,
        hintStyle: TextStyle(color: scheme.onSurface.withAlpha(60)),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: ThemeConstants.pillPadding.vertical - 27,
        ),
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: scheme.outline),
        ),
      ),
    );
  }
}
