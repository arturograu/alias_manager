import 'dart:io';

import 'package:alias_manager/data/alias_service/alias_service.dart';

/// Service to migrate aliases from RC files (.bashrc/.zshrc) to .bash_aliases
class AliasMigrationService {
  AliasMigrationService({String? rcFilePath, String? aliasFilePath})
    : _rcFile = rcFilePath ?? _detectRcFile(),
      _aliasFile = aliasFilePath ?? _detectAliasFile();

  final String _rcFile;
  final String _aliasFile;

  static String _detectRcFile() {
    final home = Platform.environment['HOME'] ?? '';
    final shell = Platform.environment['SHELL'] ?? '';
    if (shell.contains('zsh')) return '$home/.zshrc';
    return '$home/.bashrc';
  }

  static String _detectAliasFile() {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.bash_aliases';
  }

  /// Checks if there are aliases in the RC file that need to be migrated
  Future<bool> hasAliasesToMigrate() async {
    final aliases = await _extractAliasesFromRcFile();
    return aliases.isNotEmpty;
  }

  /// Extracts aliases from the RC file
  Future<List<Alias>> getAliasesToMigrate() async {
    return await _extractAliasesFromRcFile();
  }

  /// Extracts alias definitions from the RC file
  Future<List<Alias>> _extractAliasesFromRcFile() async {
    final rcFile = File(_rcFile);
    if (!await rcFile.exists()) {
      return [];
    }

    final content = await rcFile.readAsString();
    final lines = content.split('\n');

    final aliases = <Alias>[];
    for (final line in lines) {
      final trimmed = line.trim();
      // Look for lines that start with 'alias ' and contain '='
      if (trimmed.startsWith('alias ') && trimmed.contains('=')) {
        // Remove 'alias ' prefix
        var aliasLine = trimmed.substring(6).trim();

        // Find the first '='
        final eqIndex = aliasLine.indexOf('=');
        if (eqIndex == -1) continue;

        final name = aliasLine.substring(0, eqIndex).trim();
        var command = aliasLine.substring(eqIndex + 1).trim();

        // Remove surrounding quotes if they match
        if (command.length > 1 &&
            ((command.startsWith('"') && command.endsWith('"')) ||
                (command.startsWith("'") && command.endsWith("'")))) {
          command = command.substring(1, command.length - 1);
        }

        aliases.add(Alias(name: name, command: command));
      }
    }

    return aliases;
  }

  /// Migrates aliases from RC file to .bash_aliases file
  /// Returns the list of migrated aliases
  Future<List<Alias>> migrateAliases() async {
    final aliases = await _extractAliasesFromRcFile();

    if (aliases.isEmpty) {
      return [];
    }

    // Ensure .bash_aliases file exists (create if it doesn't)
    final aliasFile = File(_aliasFile);
    if (!await aliasFile.exists()) {
      await aliasFile.create(recursive: true);
    }

    // Append aliases to .bash_aliases file
    final aliasFileContent = await aliasFile.readAsString();
    final existingAliases = _parseAliasesFromContent(aliasFileContent);
    final existingAliasesByName = {
      for (final alias in existingAliases) alias.name: alias,
    };
    final existingAliasNames = existingAliasesByName.keys.toSet();

    // Only add aliases that don't already exist in .bash_aliases
    final aliasesToAdd = aliases
        .where((a) => !existingAliasNames.contains(a.name))
        .toList();

    if (aliasesToAdd.isNotEmpty) {
      final buffer = StringBuffer();
      // Add a newline before new aliases if file is not empty
      if (aliasFileContent.isNotEmpty && !aliasFileContent.endsWith('\n')) {
        buffer.write('\n');
      }
      for (final alias in aliasesToAdd) {
        final escapedCommand = _escapeCommandForAliasFile(alias.command);
        buffer.writeln("alias ${alias.name}=\"$escapedCommand\"");
      }

      await aliasFile.writeAsString(buffer.toString(), mode: FileMode.append);
    }

    final aliasesToRemoveFromRcFile = [
      ...aliasesToAdd,
      ...aliases.where((alias) {
        final existing = existingAliasesByName[alias.name];
        return existing != null && existing.command == alias.command;
      }),
    ];
    await _removeAliasesFromRcFile(aliasesToRemoveFromRcFile);
    await _ensureRcFileSourcesAliasFile();

    return aliasesToAdd;
  }

  List<Alias> _parseAliasesFromContent(String content) {
    final lines = content.split('\n');
    final aliases = <Alias>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('alias ') && trimmed.contains('=')) {
        var aliasLine = trimmed.substring(6).trim();
        final eqIndex = aliasLine.indexOf('=');
        if (eqIndex == -1) continue;

        final name = aliasLine.substring(0, eqIndex).trim();
        var command = aliasLine.substring(eqIndex + 1).trim();

        if (command.length > 1 &&
            ((command.startsWith('"') && command.endsWith('"')) ||
                (command.startsWith("'") && command.endsWith("'")))) {
          command = command.substring(1, command.length - 1);
        }

        aliases.add(Alias(name: name, command: command));
      }
    }

    return aliases;
  }

  Future<void> _removeAliasesFromRcFile(List<Alias> aliases) async {
    final rcFile = File(_rcFile);
    if (!await rcFile.exists()) {
      return;
    }

    final content = await rcFile.readAsString();
    final lines = content.split('\n');
    final aliasNames = aliases.map((a) => a.name).toSet();

    // Filter out lines that define these aliases
    final filteredLines = lines.where((line) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('alias ')) return true;

      for (final aliasName in aliasNames) {
        // Check if this line defines the alias
        final pattern = RegExp('^alias $aliasName=');
        if (pattern.hasMatch(trimmed)) {
          return false;
        }
      }
      return true;
    }).toList();

    await rcFile.writeAsString(filteredLines.join('\n'));
  }

  Future<void> _ensureRcFileSourcesAliasFile() async {
    final rcFile = File(_rcFile);
    if (!await rcFile.exists()) {
      await rcFile.create(recursive: true);
    }

    final content = await rcFile.readAsString();

    // Check if the sourcing block already exists
    if (content.contains('if [ -f ~/.bash_aliases ]')) {
      return;
    }

    // Add the sourcing block
    final sourceBlock =
        '\nif [ -f ~/.bash_aliases ]; then\n    . ~/.bash_aliases\nfi\n';
    await rcFile.writeAsString('$content$sourceBlock');
  }

  String _escapeCommandForAliasFile(String command) {
    return command.replaceAll('"', r'\"');
  }
}
