import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/add_alias/state/add_alias_notifier.dart';
import 'package:alias_manager/presentation/add_alias/state/add_alias_state.dart';
import 'package:alias_manager/presentation/app/widgets/app_button.dart';
import 'package:alias_manager/presentation/app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = addAliasNotifierProvider(widget.selectedType);
    final notifier = ref.read(provider.notifier);
    final formState = ref.watch(provider);

    ref.listen<AddAliasState>(provider, (previous, next) {
      if (next.status.isSuccess) {
        _nameController.clear();
        _commandController.clear();
      }

      final errorMessage = next.errorMessage;
      if (next.status.isFailure && errorMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    });

    final isLoading = formState.isSubmitting;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: AppTextField(
            controller: _nameController,
            labelText: 'Alias name',
            hintText: widget.selectedType.nameHint,
            enabled: !isLoading,
            onChanged: notifier.onNameChanged,
            errorText: formState.aliasName.displayError?.message,
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
            onChanged: notifier.onCommandChanged,
            errorText: formState.aliasCommand.displayError?.message,
          ),
        ),
        const SizedBox(width: 8),
        AppButton.icon(
          key: Key('add_alias_button'),
          onPressed: isLoading ? null : notifier.submitForm,
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
