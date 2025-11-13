import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/add_alias/state/add_alias_notifier.dart';
import 'package:alias_manager/presentation/app/widgets/app_button.dart';
import 'package:alias_manager/presentation/app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddAliasForm extends ConsumerStatefulWidget {
  const AddAliasForm({super.key, required this.selectedType});

  final AliasType selectedType;

  @override
  ConsumerState<AddAliasForm> createState() => _AddAliasFormState();
}

class _AddAliasFormState extends ConsumerState<AddAliasForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _commandController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _commandController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _addAlias() {
    final name = _nameController.text.trim();
    final command = _commandController.text.trim();

    if (name.isEmpty || command.isEmpty) return;

    final alias = Alias(
      name: name,
      command: command,
      type: widget.selectedType,
    );
    ref
        .read(addAliasNotifierProvider.notifier)
        .addAlias(alias, widget.selectedType);
  }

  void _onSuccess() {
    _nameController.clear();
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(addAliasNotifierProvider, (previous, next) {
      final isSuccess = previous?.isLoading == true && next.hasValue;
      if (isSuccess) {
        _onSuccess();
      }

      final isError = previous?.isLoading == true && next.hasError;
      if (isError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    final state = ref.watch(addAliasNotifierProvider);
    final isLoading = state.isLoading;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: AppTextField(
            controller: _nameController,
            labelText: 'Alias name',
            hintText: widget.selectedType.nameHint,
            enabled: !isLoading,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: AppTextField(
            controller: _commandController,
            labelText: 'Command',
            hintText: widget.selectedType.commandHint,
            enabled: !isLoading,
          ),
        ),
        const SizedBox(width: 8),
        AppButton.icon(
          key: Key('add_alias_button'),
          onPressed: isLoading ? null : _addAlias,
          icon: Icons.add,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

extension on AliasType {
  String get nameHint => isShell ? 'll' : 'lg';
  String get commandHint => isShell ? 'ls -alF' : 'log --oneline';
}
