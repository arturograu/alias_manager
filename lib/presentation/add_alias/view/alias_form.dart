import 'package:alias_manager/presentation/app/widgets/app_button.dart';
import 'package:alias_manager/presentation/app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

class AliasForm extends StatelessWidget {
  const AliasForm({
    super.key,
    required this.nameHint,
    required this.commandHint,
    required this.nameController,
    required this.commandController,
    required this.onAddAlias,
  });

  final String nameHint;
  final String commandHint;
  final TextEditingController nameController;
  final TextEditingController commandController;
  final VoidCallback onAddAlias;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: AppTextField(
            controller: nameController,
            labelText: 'Alias name',
            hintText: nameHint,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: AppTextField(
            controller: commandController,
            labelText: 'Command',
            hintText: commandHint,
          ),
        ),
        const SizedBox(width: 8),
        AppButton.icon(
          key: Key('add_alias_button'),
          onPressed: onAddAlias,
          icon: Icons.add,
          child: Text('Add'),
        ),
      ],
    );
  }
}
