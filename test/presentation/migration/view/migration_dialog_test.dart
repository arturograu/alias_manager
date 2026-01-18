import 'package:alias_manager/domain/alias_repository/models/alias.dart';
import 'package:alias_manager/presentation/migration/view/migration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MigrationDialog', () {
    final testAliases = [
      const Alias(name: 'll', command: 'ls -la', type: AliasType.shell),
      const Alias(name: 'gs', command: 'git status', type: AliasType.shell),
    ];

    testWidgets('renders correctly with multiple aliases', (tester) async {
      var confirmCalled = false;
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              aliases: testAliases,
              onConfirm: () => confirmCalled = true,
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Migrate Aliases'), findsOneWidget);
      expect(find.text('Aliases to migrate:'), findsOneWidget);
      expect(find.text('ll'), findsOneWidget);
      expect(find.text('ls -la'), findsOneWidget);
      expect(find.text('gs'), findsOneWidget);
      expect(find.text('git status'), findsOneWidget);
      expect(find.text('Migrate'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Contains correct plural text
      expect(find.textContaining('We found 2 aliases'), findsOneWidget);

      expect(confirmCalled, isFalse);
      expect(cancelCalled, isFalse);
    });

    testWidgets('renders correctly with single alias', (tester) async {
      final singleAlias = [
        const Alias(name: 'll', command: 'ls -la', type: AliasType.shell),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              aliases: singleAlias,
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ),
      );

      // Contains correct singular text
      expect(find.textContaining('We found 1 alias in'), findsOneWidget);
    });

    testWidgets('calls onConfirm when Migrate button is pressed', (
      tester,
    ) async {
      var confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              aliases: testAliases,
              onConfirm: () => confirmCalled = true,
              onCancel: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Migrate'));
      await tester.pumpAndSettle();

      expect(confirmCalled, isTrue);
    });

    testWidgets('calls onCancel when Cancel button is pressed', (tester) async {
      var cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MigrationDialog(
              aliases: testAliases,
              onConfirm: () {},
              onCancel: () => cancelCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    group('MigrationDialog.show', () {
      testWidgets('shows dialog and returns true on confirm', (tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await MigrationDialog.show(
                    context,
                    aliases: testAliases,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Migrate Aliases'), findsOneWidget);

        await tester.tap(find.text('Migrate'));
        await tester.pumpAndSettle();

        expect(result, isTrue);
      });

      testWidgets('shows dialog and returns false on cancel', (tester) async {
        bool? result;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await MigrationDialog.show(
                    context,
                    aliases: testAliases,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(result, isFalse);
      });
    });
  });
}
