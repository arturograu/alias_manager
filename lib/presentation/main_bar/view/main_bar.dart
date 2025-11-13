import 'package:alias_manager/gen/assets.gen.dart';
import 'package:flutter/material.dart';

class MainBar extends StatelessWidget {
  const MainBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Assets.images.logo.image(width: 515 / 16, height: 548 / 16),
        child,
        SizedBox(width: 515 / 16),
      ],
    );
  }
}
