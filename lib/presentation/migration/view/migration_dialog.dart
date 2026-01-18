import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:flutter/material.dart';

class MigrationDialog extends StatelessWidget {
  const MigrationDialog({
    super.key,
    required this.aliases,
    required this.onConfirm,
    required this.onCancel,
  });

  final List<Alias> aliases;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aliasesCount = aliases.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Migrate Aliases', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 16),
            Text(
              'We found $aliasesCount alias${aliasesCount == 1 ? '' : 'es'} in '
              'your shell configuration file (.bashrc/.zshrc). '
              'It\'s recommended to use a separate .bash_aliases file for '
              'better organization.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Aliases to migrate:',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: aliases.length,
                  itemBuilder: (context, index) {
                    final alias = aliases[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 6, right: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alias.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  alias.command,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Migrate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required List<Alias> aliases,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MigrationDialogWrapper(aliases: aliases),
    );
  }
}

class _MigrationDialogWrapper extends StatefulWidget {
  const _MigrationDialogWrapper({required this.aliases});

  final List<Alias> aliases;

  @override
  State<_MigrationDialogWrapper> createState() =>
      _MigrationDialogWrapperState();
}

class _MigrationDialogWrapperState extends State<_MigrationDialogWrapper> {
  bool _isMigrating = false;

  void _handleConfirm() async {
    setState(() {
      _isMigrating = true;
    });

    // The actual migration will be handled by the caller
    // This dialog just returns true to indicate confirmation
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isMigrating) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Migrating aliases...'),
            ],
          ),
        ),
      );
    }

    return MigrationDialog(
      aliases: widget.aliases,
      onConfirm: _handleConfirm,
      onCancel: _handleCancel,
    );
  }
}
