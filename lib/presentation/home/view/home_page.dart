import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/add_alias/view/add_alias_form.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AliasListState>>(homeNotifierProvider, (prev, next) {
      final hasErrorAfterLoading =
          next.hasError && (prev == null || prev.isLoading);
      if (hasErrorAfterLoading) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    final state = ref.watch(homeNotifierProvider);

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: switch (state) {
          AsyncData(:final value) => Column(
            children: [
              MainBar(
                child: AliasTypeSelector(
                  selectedType: value.selectedType,
                  onChanged: (type) =>
                      ref.read(homeNotifierProvider.notifier).changeType(type),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AppLayoutWrapper(
                  child: AppCard(
                    child: _Body(
                      selectedType: value.selectedType,
                      aliases: value.selectedType.isShell
                          ? value.shellAliases
                          : value.gitAliases,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncError(:final error) => Center(child: Text('Error: $error')),
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.selectedType, required this.aliases});

  final AliasType selectedType;
  final List<Alias> aliases;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        AppInnerCard(child: AddAliasForm(selectedType: selectedType)),
        const SizedBox(height: 18),
        Expanded(
          child: AppInnerCard(
            child: AliasList(aliases: aliases, selectedType: selectedType),
          ),
        ),
      ],
    );
  }
}
