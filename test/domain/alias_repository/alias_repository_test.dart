import 'package:alias_manager/data/alias_service/alias_service.dart'
    as alias_service;
import 'package:alias_manager/data/alias_service/git_alias_service.dart';
import 'package:alias_manager/data/alias_service/shell_alias_service.dart';
import 'package:alias_manager/domain/alias_repository/alias_repository.dart';
import 'package:alias_manager/domain/alias_repository/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGitAliasSource extends Mock implements GitAliasSource {}

class MockShellAliasSource extends Mock implements ShellAliasSource {}

void main() {
  late MockGitAliasSource mockGitAliasSource;
  late MockShellAliasSource mockShellAliasSource;
  late AliasRepository repository;

  setUp(() {
    mockGitAliasSource = MockGitAliasSource();
    mockShellAliasSource = MockShellAliasSource();
    repository = AliasRepository(
      gitAliasSource: mockGitAliasSource,
      shellAliasSource: mockShellAliasSource,
    );
  });

  setUpAll(() {
    registerFallbackValue(
      alias_service.Alias(name: 'test', command: 'test command'),
    );
  });

  group('AliasRepository', () {
    group('fetchAliases', () {
      test('fetches and combines git and shell aliases', () async {
        final gitAliases = [
          alias_service.Alias(name: 'ga', command: 'git add'),
          alias_service.Alias(name: 'gc', command: 'git commit'),
        ];
        final shellAliases = [
          alias_service.Alias(name: 'll', command: 'ls -la'),
          alias_service.Alias(name: 'la', command: 'ls -a'),
        ];

        when(
          () => mockGitAliasSource.getAliases(),
        ).thenAnswer((_) async => gitAliases);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => shellAliases);

        final result = await repository.fetchAliases();

        expect(result.length, 4);
        expect(result.where((a) => a.type == AliasType.git).length, 2);
        expect(result.where((a) => a.type == AliasType.shell).length, 2);
        verify(() => mockGitAliasSource.getAliases()).called(1);
        verify(() => mockShellAliasSource.getAliases()).called(1);
      });

      test('updates the aliases stream when fetching', () async {
        final gitAliases = [
          alias_service.Alias(name: 'ga', command: 'git add'),
        ];
        final shellAliases = [
          alias_service.Alias(name: 'll', command: 'ls -la'),
        ];

        when(
          () => mockGitAliasSource.getAliases(),
        ).thenAnswer((_) async => gitAliases);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => shellAliases);

        await repository.fetchAliases();

        await expectLater(repository.aliases, emits(hasLength(2)));
      });

      test('handles empty results from both sources', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        final result = await repository.fetchAliases();

        expect(result, isEmpty);
      });

      test('propagates errors from git source', () async {
        when(
          () => mockGitAliasSource.getAliases(),
        ).thenThrow(Exception('Git error'));
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        expect(() => repository.fetchAliases(), throwsA(isA<Exception>()));
      });

      test('propagates errors from shell source', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenThrow(Exception('Shell error'));

        expect(() => repository.fetchAliases(), throwsA(isA<Exception>()));
      });
    });

    group('addAlias', () {
      test('adds a git alias and updates the stream', () async {
        final alias = Alias(
          name: 'ga',
          command: 'git add',
          type: AliasType.git,
        );

        when(
          () => mockGitAliasSource.addAlias(any()),
        ).thenAnswer((_) async => {});

        await repository.addAlias(alias, AliasType.git);

        verify(() => mockGitAliasSource.addAlias(any())).called(1);
        verifyNever(() => mockShellAliasSource.addAlias(any()));

        await expectLater(repository.aliases, emits(contains(alias)));
      });

      test('adds a shell alias and updates the stream', () async {
        final alias = Alias(
          name: 'll',
          command: 'ls -la',
          type: AliasType.shell,
        );

        when(
          () => mockShellAliasSource.addAlias(any()),
        ).thenAnswer((_) async => {});

        await repository.addAlias(alias, AliasType.shell);

        verify(() => mockShellAliasSource.addAlias(any())).called(1);
        verifyNever(() => mockGitAliasSource.addAlias(any()));

        await expectLater(repository.aliases, emits(contains(alias)));
      });

      test('propagates errors from git source', () async {
        final alias = Alias(
          name: 'ga',
          command: 'git add',
          type: AliasType.git,
        );

        when(
          () => mockGitAliasSource.addAlias(any()),
        ).thenThrow(Exception('Failed to add'));

        expect(
          () => repository.addAlias(alias, AliasType.git),
          throwsA(isA<Exception>()),
        );
      });

      test('propagates errors from shell source', () async {
        final alias = Alias(
          name: 'll',
          command: 'ls -la',
          type: AliasType.shell,
        );

        when(
          () => mockShellAliasSource.addAlias(any()),
        ).thenThrow(Exception('Failed to add'));

        expect(
          () => repository.addAlias(alias, AliasType.shell),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteAlias', () {
      test('deletes a git alias and updates the stream', () async {
        // First add some aliases
        final gitAliases = [
          alias_service.Alias(name: 'ga', command: 'git add'),
          alias_service.Alias(name: 'gc', command: 'git commit'),
        ];
        when(
          () => mockGitAliasSource.getAliases(),
        ).thenAnswer((_) async => gitAliases);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        await repository.fetchAliases();

        when(
          () => mockGitAliasSource.deleteAlias('ga'),
        ).thenAnswer((_) async => {});

        await repository.deleteAlias('ga', AliasType.git);

        verify(() => mockGitAliasSource.deleteAlias('ga')).called(1);
        verifyNever(() => mockShellAliasSource.deleteAlias(any()));

        final aliases = await repository.aliases.first;
        expect(aliases.where((a) => a.name == 'ga'), isEmpty);
        expect(aliases.where((a) => a.name == 'gc'), hasLength(1));
      });

      test('deletes a shell alias and updates the stream', () async {
        // First add some aliases
        final shellAliases = [
          alias_service.Alias(name: 'll', command: 'ls -la'),
          alias_service.Alias(name: 'la', command: 'ls -a'),
        ];
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => shellAliases);

        await repository.fetchAliases();

        when(
          () => mockShellAliasSource.deleteAlias('ll'),
        ).thenAnswer((_) async => {});

        await repository.deleteAlias('ll', AliasType.shell);

        verify(() => mockShellAliasSource.deleteAlias('ll')).called(1);
        verifyNever(() => mockGitAliasSource.deleteAlias(any()));

        final aliases = await repository.aliases.first;
        expect(aliases.where((a) => a.name == 'll'), isEmpty);
        expect(aliases.where((a) => a.name == 'la'), hasLength(1));
      });

      test('propagates errors from git source', () async {
        when(
          () => mockGitAliasSource.deleteAlias(any()),
        ).thenThrow(Exception('Failed to delete'));

        expect(
          () => repository.deleteAlias('ga', AliasType.git),
          throwsA(isA<Exception>()),
        );
      });

      test('propagates errors from shell source', () async {
        when(
          () => mockShellAliasSource.deleteAlias(any()),
        ).thenThrow(Exception('Failed to delete'));

        expect(
          () => repository.deleteAlias('ll', AliasType.shell),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('aliases stream', () {
      test('provides access to the aliases stream', () {
        expect(repository.aliases, isA<Stream<List<Alias>>>());
      });

      test('emits empty list initially', () async {
        expect(repository.aliases, emits(isEmpty));
      });

      test('can be listened to multiple times without errors', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        // Listen multiple times
        final subscription1 = repository.aliases.listen((_) {});
        final subscription2 = repository.aliases.listen((_) {});

        await repository.fetchAliases();

        // Should not throw
        await subscription1.cancel();
        await subscription2.cancel();
      });

      test('subscription can be cancelled without errors', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        final subscription = repository.aliases.listen((_) {});

        await repository.fetchAliases();

        // Cancelling should not throw and prevent memory leaks
        await expectLater(subscription.cancel(), completes);
      });

      test('emits values after multiple fetch operations', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        final emittedValues = <List>[];
        final subscription = repository.aliases.listen(emittedValues.add);

        await repository.fetchAliases();
        await repository.fetchAliases();
        await repository.fetchAliases();

        // Should emit at least 3 values (initial + 3 fetches)
        expect(emittedValues.length, greaterThanOrEqualTo(3));

        await subscription.cancel();
      });

      test('concurrent listeners do not interfere with each other', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        final listener1Values = <List>[];
        final listener2Values = <List>[];

        final subscription1 = repository.aliases.listen(listener1Values.add);
        final subscription2 = repository.aliases.listen(listener2Values.add);

        await repository.fetchAliases();

        // Both listeners should receive the same values
        expect(listener1Values.length, greaterThan(0));
        expect(listener2Values.length, greaterThan(0));

        await subscription1.cancel();
        await subscription2.cancel();
      });

      test('does not retain references to external data', () async {
        final gitAliases = [
          alias_service.Alias(name: 'ga', command: 'git add'),
        ];
        final shellAliases = [
          alias_service.Alias(name: 'll', command: 'ls -la'),
        ];

        when(
          () => mockGitAliasSource.getAliases(),
        ).thenAnswer((_) async => gitAliases);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => shellAliases);

        await repository.fetchAliases();

        // Clear the original lists
        gitAliases.clear();
        shellAliases.clear();

        // Repository should still have its own copy of the data
        final aliases = await repository.aliases.first;
        expect(aliases.length, 2);
      });
    });
  });
}
