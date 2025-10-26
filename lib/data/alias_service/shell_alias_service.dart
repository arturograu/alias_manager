import 'dart:io';

import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:system_command_runner/system_command_runner.dart';

class ShellAliasSource implements AliasSource {
  ShellAliasSource({SystemCommandRunner? commandRunner})
    : _commandRunner = commandRunner ?? const SystemCommandRunner(),
      _shell = _detectShell(),
      _rcFile = _detectRcFile();

  final SystemCommandRunner _commandRunner;
  final String _shell;
  final String _rcFile;

  static String _detectShell() {
    final shell = Platform.environment['SHELL'] ?? '';
    if (shell.contains('zsh')) return 'zsh';
    return 'bash';
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
    // Remove old alias if exists
    await deleteAlias(alias.name);

    // Build the shell command to append alias to the RC file
    final addCmd =
        "echo 'alias ${alias.name}=\"${alias.command}\"' >> $_rcFile";

    final (executable, arguments) = _buildCommand([addCmd]);
    final result = await _commandRunner.run(executable, arguments);

    if (_isInvalidExitCode(result.exitCode)) {
      throw Exception('Failed to add alias: ${result.stderr}');
    }
  }

  @override
  Future<List<Alias>> getAliases() async {
    final (executable, arguments) = _buildCommand(['source $_rcFile && alias']);
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
    // Remove any line starting with alias <name>= from the RC file
    // -i '' is for in-place editing (macOS/BSD sed syntax)
    final removeCmd = "sed -i '' '/alias $name=/d' $_rcFile";

    final (executable, arguments) = _buildCommand([removeCmd]);
    final result = await _commandRunner.run(executable, arguments);

    if (_isInvalidExitCode(result.exitCode)) {
      throw Exception('Failed to delete alias: ${result.stderr}');
    }
  }
}
