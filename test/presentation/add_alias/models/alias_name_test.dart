import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/add_alias/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';

void main() {
  group('AliasName FormzInput', () {
    group('constructors', () {
      test('pure creates valid instance', () {
        final aliasName = AliasName.pure(aliasType: AliasType.shell);
        expect(aliasName.value, '');
        expect(aliasName.isPure, isTrue);
      });

      test('dirty creates valid instance', () {
        final aliasName = AliasName.dirty(
          value: 'myalias',
          aliasType: AliasType.shell,
        );
        expect(aliasName.value, 'myalias');
        expect(aliasName.isPure, isFalse);
      });
    });

    group('validation with formz', () {
      test('validates multiple inputs together', () {
        final validName = AliasName.dirty(
          value: 'validalias',
          aliasType: AliasType.shell,
        );
        final validCommand = AliasCommand.dirty(value: 'ls -la');

        expect(Formz.validate([validName, validCommand]), isTrue);
      });

      test('fails validation when any input is invalid', () {
        final invalidName = AliasName.dirty(
          value: 'my=alias',
          aliasType: AliasType.shell,
        );
        final validCommand = AliasCommand.dirty(value: 'ls -la');

        expect(Formz.validate([invalidName, validCommand]), isFalse);
      });
    });

    group('error caching', () {
      test('caches validation results for performance', () {
        // FormzInputErrorCacheMixin should cache the error result
        final name = AliasName.dirty(
          value: 'invalid=name',
          aliasType: AliasType.shell,
        );

        // Access error multiple times - should use cached value
        final error1 = name.error;
        final error2 = name.error;
        final error3 = name.error;

        expect(error1, equals(error2));
        expect(error2, equals(error3));
        expect(error1, AliasNameValidationError.invalidCharacters);
      });
    });

    group('copyWith', () {
      test('creates copy with new value', () {
        final original = AliasName.dirty(
          value: 'original',
          aliasType: AliasType.shell,
        );
        final copy = original.copyWith(value: 'updated');

        expect(copy.value, 'updated');
        expect(copy.aliasType, AliasType.shell);
        expect(original.value, 'original');
      });

      test('creates copy with new alias type', () {
        final original = AliasName.dirty(
          value: 'myalias',
          aliasType: AliasType.shell,
        );
        final copy = original.copyWith(aliasType: AliasType.git);

        expect(copy.value, 'myalias');
        expect(copy.aliasType, AliasType.git);
        expect(original.aliasType, AliasType.shell);
      });
    });

    group('displayError', () {
      test('returns null for pure state even with invalid value', () {
        final name = AliasName.pure(aliasType: AliasType.shell);
        expect(name.displayError, isNull);
      });

      test('returns error for dirty state with invalid value', () {
        final name = AliasName.dirty(
          value: 'my=alias',
          aliasType: AliasType.shell,
        );
        expect(name.displayError, AliasNameValidationError.invalidCharacters);
      });
    });
  });

  group('AliasCommand FormzInput', () {
    test('pure state', () {
      const command = AliasCommand.pure();
      expect(command.value, '');
      expect(command.isPure, isTrue);
    });

    test('validates non-empty command', () {
      const command = AliasCommand.dirty(value: 'ls -la');
      expect(command.isValid, isTrue);
    });

    test('rejects empty command', () {
      const command = AliasCommand.dirty(value: '');
      expect(command.isValid, isFalse);
      expect(command.error, AliasCommandValidationError.empty);
    });
  });
}
