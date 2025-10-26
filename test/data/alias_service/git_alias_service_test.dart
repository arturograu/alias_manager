import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:alias_manager/data/alias_service/git_alias_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:system_command_runner/system_command_runner.dart';

class MockSystemCommandRunner extends Mock implements SystemCommandRunner {}

void main() {
  final testAlias = Alias(name: 'testAlias', command: 'echo test');
  late MockSystemCommandRunner systemCommandRunner;
  late GitAliasSource gitAliasSource;

  setUp(() {
    systemCommandRunner = MockSystemCommandRunner();
    gitAliasSource = GitAliasSource(commandRunner: systemCommandRunner);
  });

  group('GitAliasSource', () {
    group('addAlias', () {
      test(
        'calls the system command runner with the correct arguments',
        () async {
          when(
            () => systemCommandRunner.run('git', [
              'config',
              '--global',
              'alias.${testAlias.name}',
              testAlias.command,
            ]),
          ).thenAnswer(
            (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
          );

          await gitAliasSource.addAlias(testAlias);

          verify(
            () => systemCommandRunner.run('git', [
              'config',
              '--global',
              'alias.${testAlias.name}',
              testAlias.command,
            ]),
          ).called(1);
        },
      );

      test('throws an exception if the command fails', () async {
        when(
          () => systemCommandRunner.run('git', [
            'config',
            '--global',
            'alias.${testAlias.name}',
            testAlias.command,
          ]),
        ).thenAnswer(
          (_) async => CommandResult(exitCode: 2, stdout: '', stderr: 'Error'),
        );

        expect(
          () async => gitAliasSource.addAlias(testAlias),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getAliases', () {
      test(
        'calls the system command runner with the correct arguments',
        () async {
          when(
            () => systemCommandRunner.run('git', [
              'config',
              '--global',
              '--get-regexp',
              '^alias\\.',
            ]),
          ).thenAnswer(
            (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
          );

          await gitAliasSource.getAliases();

          verify(
            () => systemCommandRunner.run('git', [
              'config',
              '--global',
              '--get-regexp',
              '^alias\\.',
            ]),
          ).called(1);
        },
      );

      test('returns a list of GitAlias from the command output', () async {
        when(
          () => systemCommandRunner.run('git', [
            'config',
            '--global',
            '--get-regexp',
            '^alias\\.',
          ]),
        ).thenAnswer(
          (_) async => CommandResult(
            exitCode: 0,
            stdout:
                'alias.testAlias echo test\nalias.anotherAlias echo another',
            stderr: '',
          ),
        );

        final aliases = await gitAliasSource.getAliases();

        expect(aliases, hasLength(2));
        expect(aliases[0].name, 'testAlias');
        expect(aliases[0].command, 'echo test');
        expect(aliases[1].name, 'anotherAlias');
        expect(aliases[1].command, 'echo another');
      });

      test('throws an exception if the command fails', () async {
        when(
          () => systemCommandRunner.run('git', [
            'config',
            '--global',
            '--get-regexp',
            '^alias\\.',
          ]),
        ).thenAnswer(
          (_) async => CommandResult(exitCode: 2, stdout: '', stderr: 'Error'),
        );

        expect(
          () async => gitAliasSource.getAliases(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteAlias', () {
      test(
        'calls the system command runner with the correct arguments',
        () async {
          when(
            () => systemCommandRunner.run('git', [
              'config',
              '--global',
              '--unset',
              'alias.${testAlias.name}',
            ]),
          ).thenAnswer(
            (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
          );

          await gitAliasSource.deleteAlias(testAlias.name);

          verify(
            () => systemCommandRunner.run('git', [
              'config',
              '--global',
              '--unset',
              'alias.${testAlias.name}',
            ]),
          ).called(1);
        },
      );

      test('throws an exception if the command fails', () async {
        when(
          () => systemCommandRunner.run('git', [
            'config',
            '--global',
            '--unset',
            'alias.${testAlias.name}',
          ]),
        ).thenAnswer(
          (_) async => CommandResult(exitCode: 2, stdout: '', stderr: 'Error'),
        );

        expect(
          () async => gitAliasSource.deleteAlias(testAlias.name),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
