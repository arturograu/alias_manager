import 'dart:io';

import 'package:alias_manager/data/alias_service/alias_migration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File rcFile;
  late File aliasFile;
  late AliasMigrationService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('alias_migration_test_');
    rcFile = File('${tempDir.path}/.zshrc');
    aliasFile = File('${tempDir.path}/.bash_aliases');
    service = AliasMigrationService(
      rcFilePath: rcFile.path,
      aliasFilePath: aliasFile.path,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AliasMigrationService', () {
    group('hasAliasesToMigrate', () {
      test('returns false when RC file does not exist', () async {
        final result = await service.hasAliasesToMigrate();

        expect(result, isFalse);
      });

      test('returns false when RC file has no aliases', () async {
        await rcFile.writeAsString('# Just a comment\nexport PATH=/usr/bin');

        final result = await service.hasAliasesToMigrate();

        expect(result, isFalse);
      });

      test('returns true when RC file has aliases', () async {
        await rcFile.writeAsString("alias ll='ls -la'\nalias la='ls -a'");

        final result = await service.hasAliasesToMigrate();

        expect(result, isTrue);
      });
    });

    group('getAliasesToMigrate', () {
      test('returns empty list when RC file does not exist', () async {
        final result = await service.getAliasesToMigrate();

        expect(result, isEmpty);
      });

      test('returns empty list when RC file has no aliases', () async {
        await rcFile.writeAsString('# Just a comment\nexport PATH=/usr/bin');

        final result = await service.getAliasesToMigrate();

        expect(result, isEmpty);
      });

      test('returns aliases from RC file', () async {
        await rcFile.writeAsString("alias ll='ls -la'\nalias la='ls -a'");

        final result = await service.getAliasesToMigrate();

        expect(result.length, 2);
        expect(result[0].name, 'll');
        expect(result[0].command, 'ls -la');
        expect(result[1].name, 'la');
        expect(result[1].command, 'ls -a');
      });

      test('handles aliases with double quotes', () async {
        await rcFile.writeAsString('alias ll="ls -la"');

        final result = await service.getAliasesToMigrate();

        expect(result.length, 1);
        expect(result[0].name, 'll');
        expect(result[0].command, 'ls -la');
      });

      test('handles multiline aliases in quotes', () async {
        await rcFile.writeAsString(
          "alias test='echo hello\nworld'\nexport PATH=/usr/bin",
        );

        final result = await service.getAliasesToMigrate();

        expect(result.length, 1);
        expect(result[0].name, 'test');
        expect(result[0].command, 'echo hello\nworld');
      });

      test('parses mixed stress-test aliases', () async {
        await rcFile.writeAsString('''
# --- Alias migration stress test ---
alias simple='echo simple'
alias multi_single='echo hello
world'
alias multi_double="echo hello
world"
alias continuation=echo\\ hello\\
world
alias double_escapes="echo \\"quoted\\" and \\\\n literal"

alias    spaced =   "echo spaced"
''');

        final result = await service.getAliasesToMigrate();
        final aliasesByName = {for (final alias in result) alias.name: alias};

        expect(aliasesByName['simple']?.command, 'echo simple');
        expect(aliasesByName['multi_single']?.command, 'echo hello\nworld');
        expect(aliasesByName['multi_double']?.command, 'echo hello\nworld');
        expect(aliasesByName['continuation']?.command, 'echo hello\nworld');
        expect(
          aliasesByName['double_escapes']?.command,
          'echo "quoted" and \\n literal',
        );
        expect(aliasesByName['spaced']?.command, 'echo spaced');
      });

      test('ignores non-alias lines', () async {
        await rcFile.writeAsString('''
# Comment
export PATH=/usr/bin
alias ll='ls -la'
source ~/.profile
alias la='ls -a'
''');

        final result = await service.getAliasesToMigrate();

        expect(result.length, 2);
      });
    });

    group('migrateAliases', () {
      test('returns empty list when no aliases to migrate', () async {
        await rcFile.writeAsString('# No aliases here');

        final result = await service.migrateAliases();

        expect(result, isEmpty);
      });

      test('creates alias file if it does not exist', () async {
        await rcFile.writeAsString("alias ll='ls -la'");

        await service.migrateAliases();

        expect(await aliasFile.exists(), isTrue);
      });

      test('writes aliases to alias file', () async {
        await rcFile.writeAsString("alias ll='ls -la'\nalias la='ls -a'");

        await service.migrateAliases();

        final content = await aliasFile.readAsString();
        expect(content, contains('alias ll="ls -la"'));
        expect(content, contains('alias la="ls -a"'));
      });

      test('escapes double quotes in migrated commands', () async {
        await rcFile.writeAsString('alias test=\'echo "hello"\'');

        await service.migrateAliases();

        final content = await aliasFile.readAsString();
        expect(content, contains('alias test="echo \\"hello\\""'));
      });

      test('removes aliases from RC file', () async {
        await rcFile.writeAsString('''
# Comment
alias ll='ls -la'
export PATH=/usr/bin
alias la='ls -a'
''');

        await service.migrateAliases();

        final content = await rcFile.readAsString();
        expect(content, isNot(contains("alias ll='ls -la'")));
        expect(content, isNot(contains("alias la='ls -a'")));
        expect(content, contains('# Comment'));
        expect(content, contains('export PATH=/usr/bin'));
      });

      test(
        'removes multiline aliases from RC file without leftovers',
        () async {
          await rcFile.writeAsString(
            "alias test='echo hello\nworld'\nexport PATH=/usr/bin\n",
          );

          await service.migrateAliases();

          final content = await rcFile.readAsString();
          expect(content, isNot(contains("alias test='echo hello")));
          expect(content, isNot(contains("world'")));
          expect(content, contains('export PATH=/usr/bin'));

          final aliasContent = await aliasFile.readAsString();
          expect(aliasContent, contains('alias test="echo hello\nworld"'));
        },
      );

      test('migrates stress-test aliases without RC leftovers', () async {
        await rcFile.writeAsString('''
# --- Alias migration stress test ---
alias simple='echo simple'
alias multi_single='echo hello
world'
alias multi_double="echo hello
world"
alias continuation=echo\\ hello\\
world
alias double_escapes="echo \\"quoted\\" and \\\\n literal"

alias    spaced =   "echo spaced"
''');

        await service.migrateAliases();

        final rcContent = await rcFile.readAsString();
        expect(rcContent, contains('# --- Alias migration stress test ---'));
        expect(rcContent, isNot(contains('alias simple=')));
        expect(rcContent, isNot(contains('alias multi_single=')));
        expect(rcContent, isNot(contains('alias multi_double=')));
        expect(rcContent, isNot(contains('alias continuation=')));
        expect(rcContent, isNot(contains('alias double_escapes=')));
        expect(rcContent, isNot(contains('alias    spaced =')));
        expect(rcContent, isNot(contains('world\'')));

        final aliasContent = await aliasFile.readAsString();
        expect(aliasContent, contains('alias simple="echo simple"'));
        expect(
          aliasContent,
          contains('alias multi_single="echo hello\nworld"'),
        );
        expect(
          aliasContent,
          contains('alias multi_double="echo hello\nworld"'),
        );
        expect(
          aliasContent,
          contains('alias continuation="echo hello\nworld"'),
        );
        expect(
          aliasContent,
          contains(
            'alias double_escapes="echo \\"quoted\\" and \\\\n literal"',
          ),
        );
        expect(aliasContent, contains('alias spaced="echo spaced"'));
      });

      test('keeps conflicting aliases in RC file', () async {
        await aliasFile.writeAsString('alias ll="ls -lah"');
        await rcFile.writeAsString('alias ll=\'ls -la\'\nalias la=\'ls -a\'');

        await service.migrateAliases();

        final content = await rcFile.readAsString();
        expect(content, contains("alias ll='ls -la'"));
        expect(content, isNot(contains("alias la='ls -a'")));
      });

      test('adds sourcing block to RC file', () async {
        await rcFile.writeAsString("alias ll='ls -la'");

        await service.migrateAliases();

        final content = await rcFile.readAsString();
        expect(content, contains('if [ -f ~/.bash_aliases ]'));
        expect(content, contains('. ~/.bash_aliases'));
      });

      test('does not duplicate sourcing block', () async {
        await rcFile.writeAsString('''
alias ll='ls -la'
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
''');

        await service.migrateAliases();

        final content = await rcFile.readAsString();
        final matches = 'if [ -f ~/.bash_aliases ]'.allMatches(content);
        expect(matches.length, 1);
      });

      test('skips aliases that already exist in alias file', () async {
        await aliasFile.writeAsString('alias ll="ls -la"');
        await rcFile.writeAsString("alias ll='ls -la'\nalias la='ls -a'");

        final result = await service.migrateAliases();

        expect(result.length, 1);
        expect(result[0].name, 'la');
      });

      test('returns only migrated aliases', () async {
        await rcFile.writeAsString("alias ll='ls -la'\nalias la='ls -a'");

        final result = await service.migrateAliases();

        expect(result.length, 2);
        expect(result.map((a) => a.name), containsAll(['ll', 'la']));
      });
    });
  });
}
