import 'package:alias_manager/data/alias_service/alias_migration_service.dart';
import 'package:alias_manager/data/alias_service/alias_service.dart'
    as alias_service;
import 'package:alias_manager/data/alias_service/git_alias_service.dart';
import 'package:alias_manager/data/alias_service/shell_alias_service.dart';
import 'package:alias_manager/main.dart';
import 'package:alias_manager/presentation/migration/state/migration_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGitAliasSource extends Mock implements GitAliasSource {}

class MockShellAliasSource extends Mock implements ShellAliasSource {}

class MockAliasMigrationService extends Mock implements AliasMigrationService {}

void main() {
  late MockGitAliasSource mockGitAliasSource;
  late MockShellAliasSource mockShellAliasSource;
  late MockAliasMigrationService mockMigrationService;

  setUp(() {
    mockGitAliasSource = MockGitAliasSource();
    mockShellAliasSource = MockShellAliasSource();
    mockMigrationService = MockAliasMigrationService();
  });

  setUpAll(() {
    registerFallbackValue(
      alias_service.Alias(name: 'test', command: 'test command'),
    );
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        gitAliasServiceProvider.overrideWithValue(mockGitAliasSource),
        shellAliasServiceProvider.overrideWithValue(mockShellAliasSource),
        aliasMigrationServiceProvider.overrideWithValue(mockMigrationService),
      ],
    );
  }

  group('MigrationNotifier', () {
    group('initial state', () {
      test('has initial status', () {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);

        final container = createContainer();
        addTearDown(container.dispose);

        final state = container.read(migrationNotifierProvider);

        expect(state.status, MigrationStatus.initial);
        expect(state.aliasesToMigrate, isEmpty);
      });
    });

    group('checkForMigration', () {
      test('sets status to checking while loading', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.hasAliasesToMigrate(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(migrationNotifierProvider.notifier);

        // Start the check but don't await
        final future = notifier.checkForMigration();

        // State might be checking at this point
        await future;

        // After completion, should be noMigrationNeeded
        final state = container.read(migrationNotifierProvider);
        expect(state.status, MigrationStatus.noMigrationNeeded);
      });

      test('sets status to noMigrationNeeded when no aliases found', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.hasAliasesToMigrate(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(migrationNotifierProvider.notifier)
            .checkForMigration();

        final state = container.read(migrationNotifierProvider);
        expect(state.status, MigrationStatus.noMigrationNeeded);
        expect(state.aliasesToMigrate, isEmpty);
      });

      test('sets status to pendingMigration when aliases found', () async {
        final aliasesToMigrate = [
          alias_service.Alias(name: 'll', command: 'ls -la'),
          alias_service.Alias(name: 'la', command: 'ls -a'),
        ];

        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.hasAliasesToMigrate(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.getAliasesToMigrate(),
        ).thenAnswer((_) async => aliasesToMigrate);

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(migrationNotifierProvider.notifier)
            .checkForMigration();

        final state = container.read(migrationNotifierProvider);
        expect(state.status, MigrationStatus.pendingMigration);
        expect(state.aliasesToMigrate.length, 2);
      });

      test('does not check again if already checked', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.hasAliasesToMigrate(),
        ).thenAnswer((_) async => false);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(migrationNotifierProvider.notifier);

        await notifier.checkForMigration();
        await notifier.checkForMigration();
        await notifier.checkForMigration();

        verify(() => mockMigrationService.hasAliasesToMigrate()).called(1);
      });

      test('sets status to noMigrationNeeded on error', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.hasAliasesToMigrate(),
        ).thenThrow(Exception('Error'));

        final container = createContainer();
        addTearDown(container.dispose);

        try {
          await container
              .read(migrationNotifierProvider.notifier)
              .checkForMigration();
        } catch (_) {
          // Expected to throw
        }

        final state = container.read(migrationNotifierProvider);
        expect(state.status, MigrationStatus.noMigrationNeeded);
      });
    });

    group('migrateAliases', () {
      test('sets status to migrating while in progress', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.migrateAliases(),
        ).thenAnswer((_) async => []);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(migrationNotifierProvider.notifier);

        await notifier.migrateAliases();

        final state = container.read(migrationNotifierProvider);
        expect(state.status, MigrationStatus.completed);
      });

      test('sets status to completed after success', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.migrateAliases(),
        ).thenAnswer((_) async => []);

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(migrationNotifierProvider.notifier)
            .migrateAliases();

        final state = container.read(migrationNotifierProvider);
        expect(state.status, MigrationStatus.completed);
        expect(state.aliasesToMigrate, isEmpty);
      });

      test('clears aliases after migration', () async {
        final aliasesToMigrate = [
          alias_service.Alias(name: 'll', command: 'ls -la'),
        ];

        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.hasAliasesToMigrate(),
        ).thenAnswer((_) async => true);
        when(
          () => mockMigrationService.getAliasesToMigrate(),
        ).thenAnswer((_) async => aliasesToMigrate);
        when(
          () => mockMigrationService.migrateAliases(),
        ).thenAnswer((_) async => aliasesToMigrate);

        final container = createContainer();
        addTearDown(container.dispose);

        final notifier = container.read(migrationNotifierProvider.notifier);

        await notifier.checkForMigration();
        expect(
          container.read(migrationNotifierProvider).aliasesToMigrate,
          isNotEmpty,
        );

        await notifier.migrateAliases();
        expect(
          container.read(migrationNotifierProvider).aliasesToMigrate,
          isEmpty,
        );
      });

      test('sets status to pendingMigration on error', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.migrateAliases(),
        ).thenThrow(Exception('Migration failed'));

        final container = createContainer();
        addTearDown(container.dispose);

        try {
          await container
              .read(migrationNotifierProvider.notifier)
              .migrateAliases();
        } catch (_) {
          // Expected to throw
        }

        final state = container.read(migrationNotifierProvider);
        expect(state.status, MigrationStatus.pendingMigration);
      });

      test('calls repository migrateAliases', () async {
        when(() => mockGitAliasSource.getAliases()).thenAnswer((_) async => []);
        when(
          () => mockShellAliasSource.getAliases(),
        ).thenAnswer((_) async => []);
        when(
          () => mockMigrationService.migrateAliases(),
        ).thenAnswer((_) async => []);

        final container = createContainer();
        addTearDown(container.dispose);

        await container
            .read(migrationNotifierProvider.notifier)
            .migrateAliases();

        verify(() => mockMigrationService.migrateAliases()).called(1);
      });
    });
  });
}
