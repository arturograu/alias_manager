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

  /// Update the alias name field
  void onNameChanged(String value) {
    final aliasName = AliasName.dirty(value: value, aliasType: _aliasType);
    state = state.copyWith(
      aliasName: aliasName,
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Update the alias command field
  void onCommandChanged(String value) {
    final aliasCommand = AliasCommand.dirty(value: value);
    state = state.copyWith(
      aliasCommand: aliasCommand,
      status: FormzSubmissionStatus.initial,
    );
  }

  /// Submit the form and add the alias
  Future<void> submitForm() async {
    // Mark all fields as dirty to show validation errors
    state = state.copyWith(
      aliasName: AliasName.dirty(
        value: state.aliasName.value,
        aliasType: _aliasType,
      ),
      aliasCommand: AliasCommand.dirty(value: state.aliasCommand.value),
    );

    // Only proceed if form is valid
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
      // Clear form after successful submission
      state = state.clear(aliasType: _aliasType);
    } catch (e) {
      state = state.copyWith(
        status: FormzSubmissionStatus.failure,
        errorMessage: 'Failed to save alias: $e',
      );
    }
  }

  /// Clear the form
  void clearForm() {
    state = state.clear(aliasType: _aliasType);
  }
}

/// Provider for the AddAliasNotifier
final addAliasNotifierProvider =
    NotifierProvider<AddAliasNotifier, AddAliasState>(AddAliasNotifier.new);
