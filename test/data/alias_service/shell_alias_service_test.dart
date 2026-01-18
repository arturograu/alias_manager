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

  setUp(() {
    systemCommandRunner = MockSystemCommandRunner();
    shellAliasSource = ShellAliasSource(commandRunner: systemCommandRunner);
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
      test('returns an empty list when no aliases are found', () async {
        when(() => systemCommandRunner.run(any(), any())).thenAnswer(
          (_) async => CommandResult(exitCode: 0, stdout: '', stderr: ''),
        );

        final aliases = await shellAliasSource.getAliases();

        expect(aliases, isEmpty);
      });

      test('returns a list of aliases from the shell', () async {
        final mockOutput = "alias testAlias='echo test'\n";
        when(() => systemCommandRunner.run(any(), any())).thenAnswer(
          (_) async =>
              CommandResult(exitCode: 0, stdout: mockOutput, stderr: ''),
        );

        final aliases = await shellAliasSource.getAliases();

        expect(aliases.length, 1);
        expect(aliases[0].name, 'testAlias');
        expect(aliases[0].command, 'echo test');
      });

      test('throws an exception if the command fails', () async {
        when(() => systemCommandRunner.run(any(), any())).thenAnswer(
          (_) async => CommandResult(exitCode: 1, stdout: '', stderr: 'Error'),
        );

        expect(() => shellAliasSource.getAliases(), throwsA(isA<Exception>()));
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
