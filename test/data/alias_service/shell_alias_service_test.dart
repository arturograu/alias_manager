import 'dart:io';

import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:alias_manager/data/alias_service/shell_alias_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:system_command_runner/system_command_runner.dart';

class MockSystemCommandRunner extends Mock implements SystemCommandRunner {}

void main() {
  final testAlias = Alias(name: 'testAlias', command: 'echo test');
  late MockSystemCommandRunner systemCommandRunner;
  late ShellAliasSource shellAliasSource;
  late Directory tempDir;
  late String aliasFilePath;

  setUp(() async {
    systemCommandRunner = MockSystemCommandRunner();
    tempDir = await Directory.systemTemp.createTemp('alias_manager_test');
    aliasFilePath = '${tempDir.path}/.bash_aliases';
    shellAliasSource = ShellAliasSource(
      commandRunner: systemCommandRunner,
      aliasFile: aliasFilePath,
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('ShellAliasSource', () {
    group('addAlias', () {
      test('ensures RC file sources bash_aliases first', () async {
        when(() => systemCommandRunner.run(any(), any())).thenAnswer(
          (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
        );

        await shellAliasSource.addAlias(testAlias);

        final captured = verify(
          () => systemCommandRunner.run(captureAny(), captureAny()),
        ).captured;

        // First call = check if RC file sources bash_aliases
        final executable = captured[0] as String;
        final args = captured[1] as List<String>;

        expect(executable, anyOf('bash', 'zsh'));
        expect(args[0], '-c');
        expect(args[1], contains("grep -q 'if \\[ -f ~/.bash_aliases \\]'"));
      });

      test('calls deleteAlias before adding', () async {
        when(() => systemCommandRunner.run(any(), any())).thenAnswer(
          (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
        );

        await shellAliasSource.addAlias(testAlias);

        final captured = verify(
          () => systemCommandRunner.run(captureAny(), captureAny()),
        ).captured;

        // Second call = delete alias from .bash_aliases
        final executable = captured[2] as String;
        final args = captured[3] as List<String>;

        expect(executable, anyOf('bash', 'zsh'));
        expect(args[0], '-c');
        expect(args[1], contains("sed -i '' '/alias ${testAlias.name}=/d'"));
        expect(args[1], contains('.bash_aliases'));
      });

      test(
        'calls the system command runner with the correct arguments to add the alias',
        () async {
          when(() => systemCommandRunner.run(any(), any())).thenAnswer(
            (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
          );

          await shellAliasSource.addAlias(testAlias);

          final captured = verify(
            () => systemCommandRunner.run(captureAny(), captureAny()),
          ).captured;

          // Third call = add alias to .bash_aliases
          final executable = captured[4] as String;
          final args = captured[5] as List<String>;

          expect(executable, anyOf('bash', 'zsh'));
          expect(args[0], '-c');
          expect(
            args[1],
            contains(
              "echo 'alias ${testAlias.name}=\"${testAlias.command}\"' >>",
            ),
          );
          expect(args[1], contains('.bash_aliases'));
        },
      );

      test('throws exception when command fails', () async {
        // Catch-all stub that simulates failure
        when(() => systemCommandRunner.run(any(), any())).thenAnswer(
          (_) async => CommandResult(exitCode: 1, stdout: '', stderr: 'Error'),
        );

        expect(
          () => shellAliasSource.addAlias(testAlias),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getAliases', () {
      test('returns an empty list when file is missing', () async {
        final aliases = await shellAliasSource.getAliases();

        expect(aliases, isEmpty);
      });

      test('returns a list of aliases from the file', () async {
        final file = File(aliasFilePath);
        await file.writeAsString("alias testAlias='echo test'\n");

        final aliases = await shellAliasSource.getAliases();

        expect(aliases.length, 1);
        expect(aliases[0].name, 'testAlias');
        expect(aliases[0].command, 'echo test');
      });

      test('parses multiline aliases and skips stray lines', () async {
        final file = File(aliasFilePath);
        await file.writeAsString(
          [
            'alias multi_single="echo hello',
            'world"',
            'alias simple="echo simple"',
            'world"',
          ].join('\n'),
        );

        final aliases = await shellAliasSource.getAliases();

        expect(aliases.length, 2);
        expect(aliases[0].name, 'multi_single');
        expect(aliases[0].command, 'echo hello\nworld');
        expect(aliases[1].name, 'simple');
        expect(aliases[1].command, 'echo simple');
      });
    });

    group('deleteAlias', () {
      test(
        'calls the system command runner with the correct arguments',
        () async {
          when(() => systemCommandRunner.run(any(), any())).thenAnswer(
            (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
          );

          await shellAliasSource.deleteAlias(testAlias.name);

          final captured = verify(
            () => systemCommandRunner.run(captureAny(), captureAny()),
          ).captured;

          final executable = captured[0] as String;
          final args = captured[1] as List<String>;

          expect(executable, anyOf('bash', 'zsh'));
          expect(args[0], '-c');
          expect(args[1], contains("sed -i '' '/alias ${testAlias.name}=/d'"));
          expect(args[1], contains('.bash_aliases'));
        },
      );

      test('throws an exception if the command fails', () async {
        when(() => systemCommandRunner.run(any(), any())).thenAnswer(
          (_) async => CommandResult(exitCode: 1, stdout: '', stderr: 'Error'),
        );

        expect(
          () => shellAliasSource.deleteAlias(testAlias.name),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
