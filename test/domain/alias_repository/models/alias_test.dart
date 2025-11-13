import 'package:alias_manager/data/alias_service/alias_service.dart'
    as alias_service;
import 'package:alias_manager/domain/alias_repository/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AliasType', () {
    test('isShell returns true for shell type', () {
      expect(AliasType.shell.isShell, isTrue);
      expect(AliasType.git.isShell, isFalse);
    });

    test('isGit returns true for git type', () {
      expect(AliasType.git.isGit, isTrue);
      expect(AliasType.shell.isGit, isFalse);
    });
  });

  group('Alias', () {
    test('creates an alias with required fields', () {
      final alias = Alias(
        name: 'testAlias',
        command: 'echo test',
        type: AliasType.shell,
      );

      expect(alias.name, 'testAlias');
      expect(alias.command, 'echo test');
      expect(alias.type, AliasType.shell);
    });

    group('fromSourceAlias', () {
      test('creates domain alias from git source alias', () {
        final sourceAlias = alias_service.Alias(name: 'ga', command: 'git add');

        final domainAlias = Alias.fromSourceAlias(
          sourceAlias,
          type: AliasType.git,
        );

        expect(domainAlias.name, sourceAlias.name);
        expect(domainAlias.command, sourceAlias.command);
        expect(domainAlias.type, AliasType.git);
      });

      test('creates domain alias from shell source alias', () {
        final sourceAlias = alias_service.Alias(name: 'll', command: 'ls -la');

        final domainAlias = Alias.fromSourceAlias(
          sourceAlias,
          type: AliasType.shell,
        );

        expect(domainAlias.name, sourceAlias.name);
        expect(domainAlias.command, sourceAlias.command);
        expect(domainAlias.type, AliasType.shell);
      });
    });

    group('toSourceAlias', () {
      test('converts domain alias to source alias', () {
        final domainAlias = Alias(
          name: 'ga',
          command: 'git add',
          type: AliasType.git,
        );

        final sourceAlias = domainAlias.toSourceAlias();

        expect(sourceAlias.name, domainAlias.name);
        expect(sourceAlias.command, domainAlias.command);
      });

      test('does not include type in source alias', () {
        final domainAlias = Alias(
          name: 'll',
          command: 'ls -la',
          type: AliasType.shell,
        );

        final sourceAlias = domainAlias.toSourceAlias();

        // Source alias doesn't have a type property
        expect(sourceAlias.name, domainAlias.name);
        expect(sourceAlias.command, domainAlias.command);
      });
    });

    group('round-trip conversion', () {
      test('converts from source to domain and back preserves data', () {
        final originalSource = alias_service.Alias(
          name: 'gc',
          command: 'git commit',
        );

        final domain = Alias.fromSourceAlias(
          originalSource,
          type: AliasType.git,
        );
        final backToSource = domain.toSourceAlias();

        expect(backToSource.name, originalSource.name);
        expect(backToSource.command, originalSource.command);
      });
    });
  });
}
