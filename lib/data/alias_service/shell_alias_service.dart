import 'dart:io';

import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:system_command_runner/system_command_runner.dart';

class ShellAliasSource implements AliasSource {
  ShellAliasSource({SystemCommandRunner? commandRunner})
    : _commandRunner = commandRunner ?? const SystemCommandRunner(),
      _shell = _detectShell(),
      _aliasFile = _detectAliasFile(),
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
    // Source the alias file to get aliases
    final sourceCmd = "if [ -f $_aliasFile ]; then source $_aliasFile; fi && alias";
    final (executable, arguments) = _buildCommand([sourceCmd]);
    final result = await _commandRunner.run(executable, arguments);

    if (_isInvalidExitCode(result.exitCode)) {
      throw Exception('Failed to get aliases: ${result.stderr}');
    }

    final lines = result.stdout.toString().split('\n');
    return _mapLinesIntoAliases(lines);
  }

  List<Alias> _mapLinesIntoAliases(List<String> lines) {
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map((line) {
          line = line.trim();

          // Remove optional "alias " prefix
          if (line.startsWith('alias ')) {
            line = line.substring(6).trim();
          }

          // Find the first '='
          final eqIndex = line.indexOf('=');
          if (eqIndex == -1) return null;

          final name = line.substring(0, eqIndex).trim();
          var command = line.substring(eqIndex + 1).trim();

          // Remove surrounding quotes if they match
          if ((command.startsWith('"') && command.endsWith('"')) ||
              (command.startsWith("'") && command.endsWith("'"))) {
            command = command.substring(1, command.length - 1);
          }

          return Alias(name: name, command: command);
        })
        .whereType<Alias>()
        .toList();
  }

  @override
  Future<void> deleteAlias(String name) async {
    // Remove any line starting with alias <name>= from the alias file
    // -i '' is for in-place editing (macOS/BSD sed syntax)
    final removeCmd = "if [ -f $_aliasFile ]; then sed -i '' '/alias $name=/d' $_aliasFile; fi";

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
      final addCmd = '''
cat >> $_rcFile << 'EOF'
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF
''';
      final (addExecutable, addArguments) = _buildCommand([addCmd]);
      final addResult = await _commandRunner.run(addExecutable, addArguments);

      if (_isInvalidExitCode(addResult.exitCode)) {
        throw Exception('Failed to ensure RC file sources alias file: ${addResult.stderr}');
      }
    }
  }
}
