import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/gen/assets.gen.dart';
import 'package:alias_manager/presentation/app/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AliasTypeSelector extends StatelessWidget {
  const AliasTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final AliasType selectedType;
  final ValueChanged<AliasType> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: 6,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: 0,
            left: selectedType.isShell ? 0 : 38,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
              ),
            ),
          ),
          Row(
            children: [
              _SegmentButton(
                onPressed: () => onChanged(AliasType.shell),
                icon: Assets.icons.terminal,
              ),
              const SizedBox(width: 4),
              _SegmentButton(
                onPressed: () => onChanged(AliasType.git),
                icon: Assets.icons.github,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.onPressed, required this.icon});

  final VoidCallback onPressed;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: SvgPicture.asset(icon, width: 18, height: 18),
          ),
        ),
      ),
    );
  }
}
