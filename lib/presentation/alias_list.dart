import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:alias_manager/presentation/alias_type_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AliasList extends ConsumerWidget {
  const AliasList({
    super.key,
    required this.aliases,
    required this.selectedType,
    required this.onDeleteAlias,
  });

  final List<Alias> aliases;
  final AliasType selectedType;
  final ValueChanged<String> onDeleteAlias;

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
                  icon: Icon(Icons.delete, color: scheme.error),
                  // TODO: Add provider so we can call the `GitAliasSource` methods
                  // directly without needing to pass it around.
                  // This will also allow us to split the UI in a cleaner way.
                  onPressed: () => onDeleteAlias(alias.name),
                ),
              );
            },
          );
  }
}
