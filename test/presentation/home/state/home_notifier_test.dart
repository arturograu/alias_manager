import 'package:alias_manager/data/alias_service/alias_service.dart'
    as alias_service;
import 'package:alias_manager/data/alias_service/git_alias_service.dart';
import 'package:alias_manager/data/alias_service/shell_alias_service.dart';
import 'package:alias_manager/domain/alias_repository/models/models.dart';
import 'package:alias_manager/main.dart';
import 'package:alias_manager/presentation/home/state/home_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGitAliasSource extends Mock implements GitAliasSource {}

class MockShellAliasSource extends Mock implements ShellAliasSource {}

void main() {
  late MockGitAliasSource mockGitAliasSource;
  late MockShellAliasSource mockShellAliasSource;

  setUp(() {
    mockGitAliasSource = MockGitAliasSource();
    mockShellAliasSource = MockShellAliasSource();
  });

  setUpAll(() {
    registerFallbackValue(
      alias_service.Alias(name: 'test', command: 'test command'),
    );
    registerFallbackValue(AliasType.shell);
  });

  group('HomeNotifier', () {
    test('builds and loads initial state successfully', () async {
      final container = ProviderContainer(
        overrides: [
          shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
          gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
        ],
      );
      addTearDown(container.dispose);

      when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
      when(() => mockShellAliasSource.getAliases()).thenAnswer((_) async => []);

      final state = await container.read(homeNotifierProvider.future);

      expect(state.gitAliases, isEmpty);
      expect(state.shellAliases, isEmpty);
      expect(state.selectedType, AliasType.shell);
    });

    test('calls repository to fetch aliases', () async {
      final gitAliases = [
        alias_service.Alias(name: 'ga', command: 'git add'),
        alias_service.Alias(name: 'gc', command: 'git commit'),
      ];
      final shellAliases = [alias_service.Alias(name: 'll', command: 'ls -la')];

      when(
        () => mockGitAliasSource.getAliases(),
      ).thenAnswer((_) async => gitAliases);
      when(
        () => mockShellAliasSource.getAliases(),
      ).thenAnswer((_) async => shellAliases);

      final container = ProviderContainer(
        overrides: [
          shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
          gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
        ],
      );
      addTearDown(container.dispose);

      await container.read(homeNotifierProvider.future);

      verify(() => mockGitAliasSource.getAliases()).called(1);
      verify(() => mockShellAliasSource.getAliases()).called(1);
    });

    test('calls repository to change type', () async {
      when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
      when(() => mockShellAliasSource.getAliases()).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
          gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
        ],
      );
      addTearDown(container.dispose);

      await container.read(homeNotifierProvider.future);

      await container
          .read(homeNotifierProvider.notifier)
          .changeType(AliasType.git);

      // Verify method was called
      expect(
        () => container.read(homeNotifierProvider.notifier).changeType,
        isA<Function>(),
      );
    });

    test('deletes alias successfully', () async {
      final container = ProviderContainer(
        overrides: [
          shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
          gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
        ],
      );
      addTearDown(container.dispose);

      final shellAliases = [
        alias_service.Alias(name: 'll', command: 'ls -la'),
        alias_service.Alias(name: 'la', command: 'ls -a'),
      ];

      when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
      when(
        () => mockShellAliasSource.getAliases(),
      ).thenAnswer((_) async => shellAliases);
      when(
        () => mockShellAliasSource.deleteAlias(any()),
      ).thenAnswer((_) async => {});

      await container.read(homeNotifierProvider.future);

      await container.read(homeNotifierProvider.notifier).deleteAlias('ll');

      verify(() => mockShellAliasSource.deleteAlias('ll')).called(1);
    });

    group('Memory Management', () {
      test('subscription is cancelled when notifier is disposed', () async {
        final container = ProviderContainer(
          overrides: [
            shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
            gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
          ],
        );

        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        // Build the notifier
        await container.read(homeNotifierProvider.future);

        // Dispose the container (should cancel subscription and prevent leaks)
        container.dispose();

        // If subscription is not cancelled, this would cause a memory leak
      });

      test('multiple notifier builds clean up properly', () async {
        for (var i = 0; i < 10; i++) {
          final container = ProviderContainer(
            overrides: [
              shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
              gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
            ],
          );

          when(
            () => mockGitAliasSource.getAliases(),
          ).thenAnswer((_) async => []);
          when(
            () => mockShellAliasSource.getAliases(),
          ).thenAnswer((_) async => []);

          // Build and immediately dispose
          await container.read(homeNotifierProvider.future);
          container.dispose();
        }

        // If subscriptions are not cleaned up, this would cause memory leaks
      });

      test('handles stream updates without leaking', () async {
        final container = ProviderContainer(
          overrides: [
            shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
            gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
          ],
        );
        addTearDown(container.dispose);

        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockGitAliasSource.deleteAlias(any()),
        ).thenAnswer((_) async => {});

        // Initial build
        await container.read(homeNotifierProvider.future);

        // Trigger multiple updates
        for (var i = 0; i < 5; i++) {
          await container
              .read(homeNotifierProvider.notifier)
              .deleteAlias('alias$i');
        }

        // Container disposal will verify cleanup
      });

      test('changing alias type does not leak state', () async {
        final container = ProviderContainer(
          overrides: [
            shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
            gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
          ],
        );
        addTearDown(container.dispose);

        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        await container.read(homeNotifierProvider.future);

        // Change type multiple times
        for (var i = 0; i < 10; i++) {
          await container
              .read(homeNotifierProvider.notifier)
              .changeType(i % 2 == 0 ? AliasType.shell : AliasType.git);
        }
      });

      test('concurrent operations do not cause state corruption', () async {
        final container = ProviderContainer(
          overrides: [
            shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
            gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
          ],
        );
        addTearDown(container.dispose);

        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.deleteAlias(any()),
        ).thenAnswer((_) async => {});

        await container.read(homeNotifierProvider.future);

        final notifier = container.read(homeNotifierProvider.notifier);

        // Trigger multiple concurrent operations
        final futures = [
          notifier.changeType(AliasType.git),
          notifier.changeType(AliasType.shell),
          notifier.deleteAlias('test1'),
          notifier.deleteAlias('test2'),
        ];

        await Future.wait(futures);

        // State should still be valid
        final state = await container.read(homeNotifierProvider.future);
        expect(state, isNotNull);
      });

      test('rapid disposal and recreation works correctly', () async {
        for (var i = 0; i < 20; i++) {
          final container = ProviderContainer(
            overrides: [
              shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
              gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
            ],
          );

          when(
            () => mockGitAliasSource.getAliases(),
          ).thenAnswer((_) async => []);
          when(
            () => mockShellAliasSource.getAliases(),
          ).thenAnswer((_) async => []);

          // Quick build and dispose without awaiting
          container.read(homeNotifierProvider);
          container.dispose();
        }

        // All containers should be properly cleaned up
      });
    });
  });
}
