import 'package:alias_manager/gen/assets.gen.dart';
import 'package:alias_manager/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

enum AliasType {
  shell,
  git;

  bool get isShell => this == AliasType.shell;
  bool get isGit => this == AliasType.git;
}

class AliasTypeSelector extends StatefulWidget {
  const AliasTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  final AliasType selectedType;
  final ValueChanged<AliasType> onChanged;

  @override
  State<AliasTypeSelector> createState() => _CustomAliasTypeSelectorState();
}

class _CustomAliasTypeSelectorState extends State<AliasTypeSelector> {
  late AliasType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
  }

  void _onTypeSelected(AliasType type) {
    setState(() {
      _selectedType = type;
    });
    widget.onChanged(type);
  }

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
            left: _selectedType.isShell ? 0 : 38,
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
                onPressed: () => _onTypeSelected(AliasType.shell),
                icon: Assets.icons.terminal,
              ),
              const SizedBox(width: 4),
              _SegmentButton(
                onPressed: () => _onTypeSelected(AliasType.git),
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
