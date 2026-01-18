import 'package:alias_manager/domain/alias_repository/alias_repository.dart';
import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MigrationStatus {
  initial,
  checking,
  pendingMigration,
  migrating,
  completed,
  noMigrationNeeded,
}

class MigrationState {
  const MigrationState({
    this.aliasesToMigrate = const [],
    this.status = MigrationStatus.initial,
  });

  final List<Alias> aliasesToMigrate;
  final MigrationStatus status;

  MigrationState copyWith({
    List<Alias>? aliasesToMigrate,
    MigrationStatus? status,
  }) {
    return MigrationState(
      aliasesToMigrate: aliasesToMigrate ?? this.aliasesToMigrate,
      status: status ?? this.status,
    );
  }
}

class MigrationNotifier extends Notifier<MigrationState> {
  @override
  MigrationState build() {
    return const MigrationState();
  }

  AliasRepository get _repository => ref.read(aliasRepositoryProvider);

  Future<void> checkForMigration() async {
    if (state.status != MigrationStatus.initial) return;

    state = state.copyWith(status: MigrationStatus.checking);

    try {
      final hasAliases = await _repository.hasAliasesToMigrate();
      if (hasAliases) {
        final aliases = await _repository.getAliasesToMigrate();
        state = state.copyWith(
          aliasesToMigrate: aliases,
          status: MigrationStatus.pendingMigration,
        );
      } else {
        state = state.copyWith(status: MigrationStatus.noMigrationNeeded);
      }
    } catch (e) {
      state = state.copyWith(status: MigrationStatus.noMigrationNeeded);
      rethrow;
    }
  }

  Future<void> migrateAliases() async {
    state = state.copyWith(status: MigrationStatus.migrating);

    try {
      await _repository.migrateAliases();
      state = state.copyWith(
        aliasesToMigrate: [],
        status: MigrationStatus.completed,
      );
    } catch (e) {
      state = state.copyWith(status: MigrationStatus.pendingMigration);
      rethrow;
    }
  }
}

final migrationNotifierProvider =
    NotifierProvider<MigrationNotifier, MigrationState>(MigrationNotifier.new);
