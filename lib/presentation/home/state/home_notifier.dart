import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AliasListState {
  const AliasListState({
    this.gitAliases = const [],
    this.shellAliases = const [],
    this.selectedType = AliasType.shell,
  });

  final List<Alias> gitAliases;
  final List<Alias> shellAliases;
  final AliasType selectedType;

  AliasListState copyWith({
    List<Alias>? gitAliases,
    List<Alias>? shellAliases,
    AliasType? selectedType,
  }) {
    return AliasListState(
      gitAliases: gitAliases ?? this.gitAliases,
      shellAliases: shellAliases ?? this.shellAliases,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

class HomeNotifier extends AsyncNotifier<AliasListState> {
  void _onAliasesChanged(List<Alias> aliases) {
    final currentState = state.hasValue ? state.value! : const AliasListState();
    state = AsyncValue.data(
      currentState.copyWith(
        gitAliases: aliases.where((a) => a.type.isGit).toList(),
        shellAliases: aliases.where((a) => a.type.isShell).toList(),
      ),
    );
  }

  @override
  Future<AliasListState> build() async {
    try {
      ref.read(aliasRepositoryProvider).aliases.listen(_onAliasesChanged);
      final aliases = await ref.read(aliasRepositoryProvider).fetchAliases();
      return AliasListState(
        gitAliases: aliases.where((a) => a.type.isGit).toList(),
        shellAliases: aliases.where((a) => a.type.isShell).toList(),
      );
    } catch (e, s) {
      Error.throwWithStackTrace(Exception('Failed to load aliases'), s);
    }
  }

  Future<void> changeType(AliasType type) async {
    try {
      state = AsyncValue.data(state.requireValue.copyWith(selectedType: type));
    } catch (e, s) {
      state = AsyncValue.error('Failed to load aliases', s);
    }
  }

  Future<void> deleteAlias(String name) async {
    try {
      await ref
          .read(aliasRepositoryProvider)
          .deleteAlias(name, state.requireValue.selectedType);
    } catch (e, s) {
      state = AsyncValue.error('Failed to delete alias', s);
    }
  }
}

final homeNotifierProvider =
    AsyncNotifierProvider.autoDispose<HomeNotifier, AliasListState>(
      HomeNotifier.new,
    );
