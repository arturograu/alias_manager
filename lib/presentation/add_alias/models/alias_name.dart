import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:formz/formz.dart';

enum AliasNameValidationError {
  empty,
  invalidCharacters,
  startsWithNumber,
  startsWithHyphen;

  String get message {
    switch (this) {
      case AliasNameValidationError.empty:
        return 'Alias name cannot be empty';
      case AliasNameValidationError.invalidCharacters:
        return 'Alias name contains invalid characters.\n'
            r'''Avoid: = spaces ' " ` $ ; & # | < > ( ) { } [ ] \ * ? ~ !''';
      case AliasNameValidationError.startsWithNumber:
        return 'Alias name cannot start with a number';
      case AliasNameValidationError.startsWithHyphen:
        return 'Alias name cannot start with a hyphen';
    }
  }
}

class AliasName extends FormzInput<String, AliasNameValidationError>
    with FormzInputErrorCacheMixin {
  AliasName.pure({this.aliasType = AliasType.shell}) : super.pure('');

  AliasName.dirty({required String value, this.aliasType = AliasType.shell})
    : super.dirty(value);

  final AliasType aliasType;

  @override
  AliasNameValidationError? validator(String value) {
    if (value.isEmpty) {
      return AliasNameValidationError.empty;
    }

    // Only validate shell aliases for special characters
    // Git aliases can have more flexible names
    if (aliasType == AliasType.shell) {
      final invalidChars = RegExp(r'''[=\s'"`$;&#|<>(){}\[\]\\*?~!\n\r\t]''');

      if (invalidChars.hasMatch(value)) {
        return AliasNameValidationError.invalidCharacters;
      }

      // Check if name starts with a number (invalid in shell)
      if (RegExp(r'^\d').hasMatch(value)) {
        return AliasNameValidationError.startsWithNumber;
      }

      // Check if name starts with a hyphen (could be confused with flags)
      if (value.startsWith('-')) {
        return AliasNameValidationError.startsWithHyphen;
      }
    }

    return null;
  }

  AliasName copyWith({String? value, AliasType? aliasType}) {
    return AliasName.dirty(
      value: value ?? this.value,
      aliasType: aliasType ?? this.aliasType,
    );
  }
}
