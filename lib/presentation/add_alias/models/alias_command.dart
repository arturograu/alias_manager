import 'package:formz/formz.dart';

enum AliasCommandValidationError {
  empty;

  String get message => switch (this) {
    AliasCommandValidationError.empty => 'Command cannot be empty',
  };
}

extension AliasCommandValidationErrorX on AliasCommandValidationError {}

class AliasCommand extends FormzInput<String, AliasCommandValidationError> {
  const AliasCommand.pure() : super.pure('');

  const AliasCommand.dirty({String value = ''}) : super.dirty(value);

  @override
  AliasCommandValidationError? validator(String value) {
    if (value.isEmpty) {
      return AliasCommandValidationError.empty;
    }
    return null;
  }
}
