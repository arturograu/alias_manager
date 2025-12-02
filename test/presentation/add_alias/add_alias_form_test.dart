import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/add_alias/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alias Name Validation', () {
    group('Shell Alias Validation', () {
      test('accepts valid shell alias names', () {
        final name1 = AliasName.dirty(
          value: 'my_valid_alias',
          aliasType: AliasType.shell,
        );
        expect(name1.isValid, isTrue);
        expect(name1.error, isNull);

        final name2 = AliasName.dirty(
          value: 'myalias',
          aliasType: AliasType.shell,
        );
        expect(name2.isValid, isTrue);

        final name3 = AliasName.dirty(
          value: 'my_alias_123',
          aliasType: AliasType.shell,
        );
        expect(name3.isValid, isTrue);
      });

      test('rejects alias name with equals sign', () {
        final name = AliasName.dirty(
          value: 'my=alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with spaces', () {
        final name = AliasName.dirty(
          value: 'my alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with single quotes', () {
        final name = AliasName.dirty(
          value: "my'alias",
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with double quotes', () {
        final name = AliasName.dirty(
          value: 'my"alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with dollar sign', () {
        final name = AliasName.dirty(
          value: 'my\$alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with semicolon', () {
        final name = AliasName.dirty(
          value: 'my;alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with pipe', () {
        final name = AliasName.dirty(
          value: 'my|alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with backtick', () {
        final name = AliasName.dirty(
          value: 'my`alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with ampersand', () {
        final name = AliasName.dirty(
          value: 'my&alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with parentheses', () {
        final name = AliasName.dirty(
          value: 'my(alias)',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name with brackets', () {
        final name = AliasName.dirty(
          value: 'my[alias]',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.invalidCharacters);
      });

      test('rejects alias name starting with number', () {
        final name = AliasName.dirty(
          value: '1alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.startsWithNumber);
      });

      test('rejects alias name starting with hyphen', () {
        final name = AliasName.dirty(
          value: '-alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.startsWithHyphen);
      });

      test('accepts alias name with underscores and hyphens in middle', () {
        final name = AliasName.dirty(
          value: 'my_valid-alias',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isTrue);
      });

      test('accepts alias name with numbers in the middle', () {
        final name = AliasName.dirty(
          value: 'alias123',
          aliasType: AliasType.shell,
        );
        expect(name.isValid, isTrue);
      });
    });

    group('Git Alias Validation', () {
      test('accepts git alias names with special characters', () {
        // Git aliases can have more flexible names (dots are common)
        final name1 = AliasName.dirty(
          value: 'my.alias',
          aliasType: AliasType.git,
        );
        expect(name1.isValid, isTrue);

        final name2 = AliasName.dirty(
          value: 'log-graph',
          aliasType: AliasType.git,
        );
        expect(name2.isValid, isTrue);
      });
    });

    group('Empty Field Validation', () {
      test('rejects empty alias name', () {
        final name = AliasName.dirty(value: '', aliasType: AliasType.shell);
        expect(name.isValid, isFalse);
        expect(name.error, AliasNameValidationError.empty);
      });
    });

    group('Pure vs Dirty State', () {
      test('pure state does not show validation errors', () {
        final name = AliasName.pure(aliasType: AliasType.shell);
        expect(name.isPure, isTrue);
        expect(name.displayError, isNull);
      });

      test('dirty state shows validation errors', () {
        final name = AliasName.dirty(
          value: 'my=alias',
          aliasType: AliasType.shell,
        );
        expect(name.isPure, isFalse);
        expect(name.displayError, AliasNameValidationError.invalidCharacters);
      });
    });

    group('Error Messages', () {
      test('provides user-friendly error messages', () {
        expect(
          AliasNameValidationError.empty.message,
          'Alias name cannot be empty',
        );
        expect(
          AliasNameValidationError.invalidCharacters.message,
          contains('invalid characters'),
        );
        expect(
          AliasNameValidationError.startsWithNumber.message,
          'Alias name cannot start with a number',
        );
        expect(
          AliasNameValidationError.startsWithHyphen.message,
          'Alias name cannot start with a hyphen',
        );
      });
    });
  });
}
