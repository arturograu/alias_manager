import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:alias_manager/presentation/add_alias/view/alias_form.dart';
import 'package:alias_manager/presentation/app/theme/app_theme.dart';
import 'package:alias_manager/presentation/app/widgets/widgets.dart';
import 'package:alias_manager/presentation/home/state/home_notifier.dart';
import 'package:alias_manager/presentation/home/view/alias_list.dart';
import 'package:alias_manager/presentation/home/view/alias_type_selector.dart';
import 'package:alias_manager/presentation/main_bar/view/main_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AliasListPage extends ConsumerWidget {
  AliasListPage({super.key});

  final _nameController = TextEditingController();
  final _commandController = TextEditingController();

  Future<void> _addAlias(WidgetRef ref) async {
    final name = _nameController.text.trim();
    final command = _commandController.text.trim();

    if (name.isEmpty || command.isEmpty) return;

    final alias = Alias(name: name, command: command);
    ref.read(aliasListNotifierProvider.notifier).addAlias(alias);
    _nameController.clear();
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(
      aliasListNotifierProvider,
      (_, state) => state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      ),
    );

    final state = ref.watch(aliasListNotifierProvider);
    final selectedType = switch (state) {
      AsyncValue(:final value) => value?.selectedType ?? ShellAliasType(),
    };
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            MainBar(
              child: AliasTypeSelector(
                selectedType: selectedType,
                onChanged: (type) => ref
                    .read(aliasListNotifierProvider.notifier)
                    .changeType(type),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AppLayoutWrapper(
                child: AppCard(
                  child: Column(
                    children: [
                      AppInnerCard(
                        child: AliasForm(
                          nameHint: selectedType.nameHint,
                          commandHint: selectedType.commandHint,
                          nameController: _nameController,
                          commandController: _commandController,
                          onAddAlias: () => _addAlias(ref),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: AppInnerCard(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: state.isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : AliasList(
                                    aliases: switch (state) {
                                      AsyncValue(:final value) =>
                                        value?.aliases ?? [],
                                    },
                                    selectedType: selectedType,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on AliasType {
  String get nameHint => this is ShellAliasType ? 'll' : 'lg';
  String get commandHint =>
      this is ShellAliasType ? 'ls -alF' : 'log --oneline';
}
