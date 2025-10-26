import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:system_command_runner/system_command_runner.dart';

class GitAliasSource implements AliasSource {
  GitAliasSource({SystemCommandRunner? commandRunner})
    : _commandRunner = commandRunner ?? const SystemCommandRunner();

  final SystemCommandRunner _commandRunner;

  // TODO(arturograu): maybe we can find a way to improve the
  // system_command_runner package to handle this better.
  // Should be bigger bigger than 1 since 0 is a valid exit code and 1 is used
  // for valid but empty content.
  bool _isInvalidExitCode(int exitCode) => exitCode > 1;

  (String, List<String>) _buildCommand(List<String> subcommand) {
    return ('git', ['config', '--global', ...subcommand]);
  }

  @override
  Future<void> addAlias(Alias alias) async {
    final (executable, arguments) = _buildCommand([
      'alias.${alias.name}',
      alias.command,
    ]);
    final result = await _commandRunner.run(executable, arguments);

    if (_isInvalidExitCode(result.exitCode)) {
      throw Exception('Failed to add alias: ${result.stderr}');
    }
  }

  @override
  Future<List<Alias>> getAliases() async {
    final (executable, arguments) = _buildCommand([
      '--get-regexp',
      '^alias\\.',
    ]);
    final result = await _commandRunner.run(executable, arguments);

    if (_isInvalidExitCode(result.exitCode)) {
      throw Exception('Failed to get aliases: ${result.stderr}');
    }

    final lines = result.stdout.toString().split('\n');
    return lines
        .where((line) => line.trim().isNotEmpty)
        .map(_getGitAliasFromLine)
        .toList();
  }

  Alias _getGitAliasFromLine(String line) {
    final parts = line.trim().split(' ').where((p) => p.isNotEmpty).toList();
    final name = parts[0].replaceFirst('alias.', '');
    final command = parts.sublist(1).join(' ');
    return Alias(name: name, command: command);
  }

  @override
  Future<void> deleteAlias(String name) async {
    final (executable, arguments) = _buildCommand(['--unset', 'alias.$name']);
    final result = await _commandRunner.run(executable, arguments);

    if (result.exitCode != 0) {
      throw Exception('Failed to delete alias: ${result.stderr}');
    }
  }
}
