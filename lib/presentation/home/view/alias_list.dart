import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/home/state/home_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AliasList extends ConsumerWidget {
  const AliasList({
    super.key,
    required this.aliases,
    required this.selectedType,
  });

  final List<Alias> aliases;
  final AliasType selectedType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return aliases.isEmpty
        ? Text(
            'No ${selectedType.isShell ? 'shell' : 'git'} aliases found',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        : ListView.separated(
            itemCount: aliases.length,
            separatorBuilder: (_, _) => Divider(color: scheme.outline),
            itemBuilder: (_, index) {
              final alias = aliases[index];
              return ListTile(
                title: Text(alias.name),
                subtitle: Text(alias.command),
                trailing: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: scheme.error,
                  ),
                  icon: Icon(Icons.delete),
                  onPressed: () => ref
                      .read(homeNotifierProvider.notifier)
                      .deleteAlias(alias),
                ),
              );
            },
          );
  }
}
