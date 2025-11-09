import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:alias_manager/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class AliasType {
  const AliasType();
}

class ShellAliasType extends AliasType {
  const ShellAliasType();
}

class GitAliasType extends AliasType {
  const GitAliasType();
}

class AliasListState {
  const AliasListState({
    this.aliases = const [],
    this.selectedType = const ShellAliasType(),
  });

  final List<Alias> aliases;
  final AliasType selectedType;

  AliasListState copyWith({List<Alias>? aliases, AliasType? selectedType}) {
    return AliasListState(
      aliases: aliases ?? this.aliases,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

class AliasListNotifier extends AsyncNotifier<AliasListState> {
  AliasListState get _currentState => state.requireValue;

  AliasSource _resolveSource(AliasType type, Ref ref) {
    return switch (type) {
      ShellAliasType() => ref.read(shellAliasServiceProvider),
      GitAliasType() => ref.read(gitAliasServiceProvider),
    };
  }

  @override
  Future<AliasListState> build() async {
    try {
      state = AsyncValue.loading();
      final source = ref.read(shellAliasServiceProvider);
      final aliases = await source.getAliases();
      return AliasListState(aliases: aliases, selectedType: ShellAliasType());
    } catch (e, s) {
      Error.throwWithStackTrace(Exception('Failed to load aliases'), s);
    }
  }

  Future<void> changeType(AliasType type) async {
    try {
      state = AsyncValue.loading();
      final source = _resolveSource(type, ref);
      final aliases = await source.getAliases();
      state = AsyncValue.data(
        AliasListState(aliases: aliases, selectedType: type),
      );
    } catch (e, s) {
      state = AsyncValue.error('Failed to load aliases', s);
    }
  }

  Future<void> addAlias(Alias alias) async {
    final currentState = _currentState;
    final source = _resolveSource(currentState.selectedType, ref);

    try {
      await source.addAlias(alias);
      final updated = [...currentState.aliases, alias];
      state = AsyncValue.data(currentState.copyWith(aliases: updated));
    } catch (e, s) {
      state = AsyncValue.error('Failed to save alias', s);
    }
  }

  Future<void> deleteAlias(String name) async {
    final currentState = _currentState;
    final source = _resolveSource(currentState.selectedType, ref);

    try {
      await source.deleteAlias(name);
      final updated = currentState.aliases
          .where((a) => a.name != name)
          .toList();
      state = AsyncValue.data(currentState.copyWith(aliases: updated));
    } catch (e, s) {
      state = AsyncValue.error('Failed to delete alias', s);
    }
  }
}

final aliasListNotifierProvider =
    AsyncNotifierProvider.autoDispose<AliasListNotifier, AliasListState>(
      AliasListNotifier.new,
    );
