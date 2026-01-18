import 'dart:convert';
import 'dart:io';

import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:system_command_runner/system_command_runner.dart';

class ShellAliasSource implements AliasSource {
  ShellAliasSource({SystemCommandRunner? commandRunner, String? aliasFile})
    : _commandRunner = commandRunner ?? const SystemCommandRunner(),
      _shell = _detectShell(),
      _aliasFile = aliasFile ?? _detectAliasFile(),
      _rcFile = _detectRcFile();

  final SystemCommandRunner _commandRunner;
  final String _shell;
  final String _aliasFile;
  final String _rcFile;

  static String _detectShell() {
    final shell = Platform.environment['SHELL'] ?? '';
    if (shell.contains('zsh')) return 'zsh';
    return 'bash';
  }

  static String _detectAliasFile() {
    final home = Platform.environment['HOME'] ?? '';
    return '$home/.bash_aliases';
  }

  static String _detectRcFile() {
    final home = Platform.environment['HOME'] ?? '';
    final shell = Platform.environment['SHELL'] ?? '';
    if (shell.contains('zsh')) return '$home/.zshrc';
    return '$home/.bashrc';
  }

  (String, List<String>) _buildCommand(List<String> subcommand) {
    return (_shell, ['-c', ...subcommand]);
  }

  bool _isInvalidExitCode(int exitCode) => exitCode != 0;

  @override
  Future<void> addAlias(Alias alias) async {
    // Ensure the RC file sources the alias file
    await _ensureRcFileSourcesAliasFile();

    // Remove old alias if exists
    await deleteAlias(alias.name);

    // Build the shell command to append alias to the alias file
    final addCmd =
        "echo 'alias ${alias.name}=\"${alias.command}\"' >> $_aliasFile";

    final (executable, arguments) = _buildCommand([addCmd]);
    final result = await _commandRunner.run(executable, arguments);

    if (_isInvalidExitCode(result.exitCode)) {
      throw Exception('Failed to add alias: ${result.stderr}');
    }
  }

  @override
  Future<List<Alias>> getAliases() async {
    final file = File(_aliasFile);
    if (!await file.exists()) {
      return [];
    }

    try {
      final contents = await file.readAsString();
      return _parseAliasFile(contents);
    } catch (e) {
      throw Exception('Failed to get aliases: $e');
    }
  }

  List<Alias> _parseAliasFile(String contents) {
    final aliases = <Alias>[];
    final lines = const LineSplitter().convert(contents);

    String? pendingName;
    String? pendingQuote;
    final buffer = StringBuffer();

    for (final line in lines) {
      if (pendingName != null && pendingQuote != null) {
        final closingIndex = _findClosingQuote(line, pendingQuote);
        if (closingIndex != -1) {
          buffer.write(line.substring(0, closingIndex));
          aliases.add(Alias(name: pendingName, command: buffer.toString()));
          pendingName = null;
          pendingQuote = null;
          buffer.clear();
          continue;
        }

        buffer.write(line);
        buffer.write('\n');
        continue;
      }

      final trimmedLeft = line.trimLeft();
      if (!trimmedLeft.startsWith('alias ')) {
        continue;
      }

      final aliasBody = trimmedLeft.substring(6);
      final eqIndex = aliasBody.indexOf('=');
      if (eqIndex == -1) {
        continue;
      }

      final name = aliasBody.substring(0, eqIndex).trim();
      if (name.isEmpty) {
        continue;
      }

      final rawValue = aliasBody.substring(eqIndex + 1).trimRight();
      if (rawValue.isEmpty) {
        continue;
      }

      final firstChar = rawValue[0];
      if (firstChar == '"' || firstChar == "'") {
        final valueBody = rawValue.substring(1);
        final closingIndex = _findClosingQuote(valueBody, firstChar);
        if (closingIndex != -1) {
          aliases.add(
            Alias(name: name, command: valueBody.substring(0, closingIndex)),
          );
        } else {
          pendingName = name;
          pendingQuote = firstChar;
          buffer.write(valueBody);
          buffer.write('\n');
        }
        continue;
      }

      aliases.add(Alias(name: name, command: rawValue));
    }

    return aliases;
  }

  int _findClosingQuote(String value, String quote) {
    for (var i = 0; i < value.length; i++) {
      if (value[i] != quote) continue;
      if (quote == '"' && i > 0 && value[i - 1] == r'\') {
        continue;
      }
      return i;
    }
    return -1;
  }

  @override
  Future<void> deleteAlias(String name) async {
    // Remove any line starting with alias <name>= from the alias file
    // -i '' is for in-place editing (macOS/BSD sed syntax)
    final removeCmd =
        "if [ -f $_aliasFile ]; then sed -i '' '/alias $name=/d' $_aliasFile; fi";

    final (executable, arguments) = _buildCommand([removeCmd]);
    final result = await _commandRunner.run(executable, arguments);

    if (_isInvalidExitCode(result.exitCode)) {
      throw Exception('Failed to delete alias: ${result.stderr}');
    }
  }

  /// Ensures the RC file sources the .bash_aliases file
  Future<void> _ensureRcFileSourcesAliasFile() async {
    // Check if the sourcing block already exists
    final checkCmd = "grep -q 'if \\[ -f ~/.bash_aliases \\]' $_rcFile";
    final (executable, arguments) = _buildCommand([checkCmd]);
    final checkResult = await _commandRunner.run(executable, arguments);

    // If the sourcing block doesn't exist (grep returns non-zero), add it
    if (_isInvalidExitCode(checkResult.exitCode)) {
      final addCmd =
          '''

cat >> $_rcFile << 'EOF'
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
''';
      final (addExecutable, addArguments) = _buildCommand([addCmd]);
      final addResult = await _commandRunner.run(addExecutable, addArguments);

      if (_isInvalidExitCode(addResult.exitCode)) {
        throw Exception(
          'Failed to ensure RC file sources alias file: ${addResult.stderr}',
        );
      }
    }
  }
}
