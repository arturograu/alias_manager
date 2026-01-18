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
