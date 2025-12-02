import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/main.dart';
import 'package:alias_manager/presentation/add_alias/models/models.dart';
import 'package:alias_manager/presentation/add_alias/state/add_alias_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

class AddAliasNotifier extends Notifier<AddAliasState> {
  AliasType _aliasType = AliasType.shell;

  @override
  AddAliasState build() {
    return AddAliasState(
      aliasName: AliasName.pure(aliasType: _aliasType),
      aliasCommand: const AliasCommand.pure(),
    );
  }

  void initialize(AliasType aliasType) {
    if (_aliasType != aliasType) {
      _aliasType = aliasType;
      state = AddAliasState(
        aliasName: AliasName.pure(aliasType: aliasType),
        aliasCommand: const AliasCommand.pure(),
      );
    }
  }

  void onNameChanged(String value) {
    final aliasName = AliasName.dirty(value: value, aliasType: _aliasType);
    state = state.copyWith(
      aliasName: aliasName,
      status: FormzSubmissionStatus.initial,
    );
  }

  void onCommandChanged(String value) {
    final aliasCommand = AliasCommand.dirty(value: value);
    state = state.copyWith(
      aliasCommand: aliasCommand,
      status: FormzSubmissionStatus.initial,
    );
  }

  Future<void> submitForm() async {
    state = state.copyWith(
      aliasName: AliasName.dirty(
        value: state.aliasName.value,
        aliasType: _aliasType,
      ),
      aliasCommand: AliasCommand.dirty(value: state.aliasCommand.value),
    );

    if (!state.isValid) return;

    state = state.copyWith(status: FormzSubmissionStatus.inProgress);

    try {
      final repository = ref.read(aliasRepositoryProvider);
      final alias = Alias(
        name: state.aliasName.value,
        command: state.aliasCommand.value,
        type: _aliasType,
      );

      await repository.addAlias(alias, _aliasType);

      state = state.copyWith(status: FormzSubmissionStatus.success);
      state = state.clear(aliasType: _aliasType);
    } catch (e) {
      state = state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'Failed to save alias: $e',
      );
    }
  }

  void clearForm() {
    state = state.clear(aliasType: _aliasType);
  }
}

final addAliasNotifierProvider =
    NotifierProvider<AddAliasNotifier, AddAliasState>(AddAliasNotifier.new);
