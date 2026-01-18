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
    final parsedAliases = _AliasParser().parseWithRanges(content);
    return parsedAliases.map((parsed) => parsed.alias).toList();
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
    final parsedAliases = _AliasParser().parseWithRanges(content);
    return parsedAliases.map((parsed) => parsed.alias).toList();
  }

  Future<void> _removeAliasesFromRcFile(List<Alias> aliases) async {
    final rcFile = File(_rcFile);
    if (!await rcFile.exists()) {
      return;
    }

    final content = await rcFile.readAsString();
    final aliasKeysToRemove = aliases
        .map((alias) => _aliasKey(alias.name, alias.command))
        .toSet();
    final parsedAliases = _AliasParser().parseWithRanges(content);
    final rangesToRemove = parsedAliases
        .where((parsed) => aliasKeysToRemove.contains(
              _aliasKey(parsed.alias.name, parsed.alias.command),
            ))
        .toList();

    if (rangesToRemove.isEmpty) {
      return;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final parsed in rangesToRemove) {
      if (parsed.rangeStart > cursor) {
        buffer.write(content.substring(cursor, parsed.rangeStart));
      }
      cursor = parsed.rangeEnd;
    }
    if (cursor < content.length) {
      buffer.write(content.substring(cursor));
    }

    await rcFile.writeAsString(buffer.toString());
  }

  String _aliasKey(String name, String command) {
    return '$name\0$command';
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
    return command
        .replaceAll('\\', r'\\')
        .replaceAll('`', r'\`')
        .replaceAll(r'$', r'\$')
        .replaceAll('"', r'\"');
  }
}

class _ParsedAlias {
  _ParsedAlias({
    required this.alias,
    required this.rangeStart,
    required this.rangeEnd,
  });

  final Alias alias;
  final int rangeStart;
  final int rangeEnd;
}

/// Minimal parser for `alias name='command'` that can span multiple lines.
///
/// Intent (Clean Code):
/// - Small, named methods with one reason to change.
/// - The caller sees clear steps, not parsing mechanics.
/// - The parsing logic explains *why* it exists, not just *how*.
class _AliasParser {
  List<_ParsedAlias> parseWithRanges(String content) {
    final parsed = <_ParsedAlias>[];
    final length = content.length;
    var lineStart = 0;

    while (lineStart < length) {
      final lineEnd = content.indexOf('\n', lineStart);
      final effectiveLineEnd = lineEnd == -1 ? length : lineEnd;
      final aliasStart = _skipWhitespace(content, lineStart, effectiveLineEnd);

      if (aliasStart < effectiveLineEnd &&
          content.startsWith('alias ', aliasStart)) {
        final parsedAlias = _parseAliasDefinition(
          content,
          aliasStart,
          lineStart,
        );
        if (parsedAlias != null) {
          parsed.add(parsedAlias);
          lineStart = parsedAlias.rangeEnd;
          continue;
        }
      }

      lineStart = effectiveLineEnd + 1;
    }

    return parsed;
  }

  int _skipWhitespace(String content, int start, int end) {
    var index = start;
    while (index < end && content.codeUnitAt(index) <= 32) {
      index++;
    }
    return index;
  }

  _ParsedAlias? _parseAliasDefinition(
    String content,
    int aliasStart,
    int rangeStart,
  ) {
    final length = content.length;
    var index = aliasStart + 'alias '.length;

    index = _skipWhitespace(content, index, length);
    if (index >= length) return null;

    final nameStart = index;
    while (index < length &&
        content[index] != '=' &&
        content.codeUnitAt(index) > 32) {
      index++;
    }

    final name = content.substring(nameStart, index).trim();
    if (name.isEmpty) return null;

    index = _skipWhitespace(content, index, length);
    if (index >= length || content[index] != '=') {
      return null;
    }

    index++;
    index = _skipWhitespace(content, index, length);
    if (index >= length) {
      return _ParsedAlias(
        alias: Alias(name: name, command: ''),
        rangeStart: rangeStart,
        rangeEnd: length,
      );
    }

    final quoteChar = content[index] == '"' || content[index] == "'"
        ? content[index]
        : null;
    final command = _readCommand(content, index, quoteChar);

    return _ParsedAlias(
      alias: Alias(name: name, command: command.value.trim()),
      rangeStart: rangeStart,
      rangeEnd: _rangeEndAfterCommand(content, command.nextIndex),
    );
  }

  _ReadResult _readCommand(String content, int start, String? quoteChar) {
    // Parsing rules (minimal, but sufficient for migration):
    // - Single quotes: literal, no escapes.
    // - Double quotes: backslash escapes the next char; "\<newline>" keeps newline.
    // - Unquoted: backslash escapes the next char; "\<newline>" keeps newline.
    if (quoteChar == null) {
      return _readUnquotedCommand(content, start);
    }
    return _readQuotedCommand(content, start + 1, quoteChar);
  }

  _ReadResult _readQuotedCommand(String content, int start, String quoteChar) {
    final length = content.length;
    final commandBuilder = StringBuffer();
    var index = start;

    while (index < length) {
      final char = content[index];
      if (char == quoteChar) {
        index++;
        break;
      }
      // Only double quotes allow escapes. Single quotes are literal.
      if (quoteChar == '"' && char == r'\' && index + 1 < length) {
        final escaped = _readEscapedInDoubleQuotes(content, index);
        commandBuilder.write(escaped.value);
        index = escaped.nextIndex;
        continue;
      }
      commandBuilder.write(char);
      index++;
    }

    return _ReadResult(commandBuilder.toString(), index);
  }

  _ReadResult _readUnquotedCommand(String content, int start) {
    final length = content.length;
    final commandBuilder = StringBuffer();
    var index = start;

    while (index < length) {
      final char = content[index];
      if (char == '\n') {
        break;
      }
      if (char == r'\' && index + 1 < length) {
        final escaped = _readEscapedUnquoted(content, index);
        commandBuilder.write(escaped.value);
        index = escaped.nextIndex;
        continue;
      }
      commandBuilder.write(char);
      index++;
    }

    return _ReadResult(commandBuilder.toString(), index);
  }

  _ReadResult _readEscapedInDoubleQuotes(String content, int backslashIndex) {
    // backslashIndex points at '\', so read the next character.
    final nextIndex = backslashIndex + 1;
    if (nextIndex >= content.length) {
      return _ReadResult(r'\', backslashIndex + 1);
    }

    if (content[nextIndex] == '\n') {
      return _ReadResult('\n', backslashIndex + 2);
    }

    return _ReadResult(content[nextIndex], backslashIndex + 2);
  }

  _ReadResult _readEscapedUnquoted(String content, int backslashIndex) {
    final nextIndex = backslashIndex + 1;
    if (nextIndex >= content.length) {
      return _ReadResult(r'\', backslashIndex + 1);
    }

    if (content[nextIndex] == '\n') {
      return _ReadResult('\n', backslashIndex + 2);
    }

    return _ReadResult(content[nextIndex], backslashIndex + 2);
  }

  int _rangeEndAfterCommand(String content, int index) {
    var rangeEnd = content.indexOf('\n', index);
    if (rangeEnd == -1) {
      rangeEnd = content.length;
    } else {
      rangeEnd += 1;
    }
    return rangeEnd;
  }
}

class _ReadResult {
  _ReadResult(this.value, this.nextIndex);

  final String value;
  final int nextIndex;
}
