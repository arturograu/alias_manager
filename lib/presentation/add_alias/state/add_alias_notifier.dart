import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddAliasNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> addAlias(Alias alias, AliasType selectedType) async {
    try {
      state = const AsyncValue.loading();
      final repository = ref.read(aliasRepositoryProvider);
      await repository.addAlias(alias, selectedType);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error('Failed to save alias', s);
    }
  }
}

final addAliasNotifierProvider =
    AsyncNotifierProvider.autoDispose<AddAliasNotifier, void>(
      AddAliasNotifier.new,
    );
