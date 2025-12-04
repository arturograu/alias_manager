import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/add_alias/models/models.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';

class AddAliasState extends Equatable with FormzMixin {
  AddAliasState({
    AliasName? aliasName,
    AliasCommand? aliasCommand,
    this.status = FormzSubmissionStatus.initial,
    this.errorMessage,
  }) : aliasName = aliasName ?? AliasName.pure(),
       aliasCommand = aliasCommand ?? const AliasCommand.pure();

  final AliasName aliasName;
  final AliasCommand aliasCommand;
  final FormzSubmissionStatus status;
  final String? errorMessage;

  @override
  List<FormzInput> get inputs => [aliasName, aliasCommand];

  bool get isSubmitting => status == FormzSubmissionStatus.inProgress;

  AddAliasState copyWith({
    AliasName? aliasName,
    AliasCommand? aliasCommand,
    FormzSubmissionStatus? status,
    String? errorMessage,
  }) {
    return AddAliasState(
      aliasName: aliasName ?? this.aliasName,
      aliasCommand: aliasCommand ?? this.aliasCommand,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  AddAliasState clear({required AliasType aliasType}) {
    return AddAliasState(
      aliasName: AliasName.pure(aliasType: aliasType),
      aliasCommand: const AliasCommand.pure(),
      status: FormzSubmissionStatus.initial,
      errorMessage: null,
    );
  }

  @override
  List<Object?> get props => [aliasName, aliasCommand, status, errorMessage];
}
