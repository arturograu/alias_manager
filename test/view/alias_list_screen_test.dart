import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:git_alias_manager/sources/alias_source.dart';
import 'package:git_alias_manager/sources/git_alias_source.dart';
import 'package:git_alias_manager/sources/shell_alias_source.dart';
import 'package:git_alias_manager/view/alias_list_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockShellAliasSource extends Mock implements ShellAliasSource {}

class MockGitAliasSource extends Mock implements GitAliasSource {}

void main() {
  group('AliasListScreen', () {
    late GitAliasSource gitAliasSource;
    late ShellAliasSource shellAliasSource;

    setUpAll(() {
      registerFallbackValue(Alias(name: '', command: ''));
    });

    setUp(() {
      gitAliasSource = MockGitAliasSource();
      shellAliasSource = MockShellAliasSource();
      when(() => shellAliasSource.getAliases()).thenAnswer((_) async => []);
      when(() => gitAliasSource.getAliases()).thenAnswer((_) async => []);
    });

    group('renders', () {
      testWidgets('empty state', (tester) async {
        when(() => shellAliasSource.getAliases()).thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: AliasListScreen(
              shellAliasSource: shellAliasSource,
              gitAliasSource: gitAliasSource,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AliasListScreen), findsOneWidget);
        expect(find.text('No shell aliases found'), findsOneWidget);
      });

      testWidgets('list of aliases', (tester) async {
        when(() => shellAliasSource.getAliases()).thenAnswer(
          (_) async => [
            Alias(name: 'alias1', command: 'command1'),
            Alias(name: 'alias2', command: 'command2'),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AliasListScreen(
              gitAliasSource: gitAliasSource,
              shellAliasSource: shellAliasSource,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AliasListScreen), findsOneWidget);
        expect(find.text('alias1'), findsOneWidget);
        expect(find.text('command1'), findsOneWidget);
        expect(find.text('alias2'), findsOneWidget);
        expect(find.text('command2'), findsOneWidget);
      });
    });

    group('calls', () {
      testWidgets('getAliases on init', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AliasListScreen(
              gitAliasSource: gitAliasSource,
              shellAliasSource: shellAliasSource,
            ),
          ),
        );

        verify(() => shellAliasSource.getAliases()).called(1);
      });

      testWidgets('addAlias when add button is pressed', (tester) async {
        final newAlias = Alias(name: 'newAlias', command: 'newCommand');
        when(
          () => shellAliasSource.addAlias(any(that: isA<Alias>())),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: AliasListScreen(
              shellAliasSource: shellAliasSource,
              gitAliasSource: gitAliasSource,
            ),
          ),
        );

        await tester.enterText(find.byType(TextField).at(0), newAlias.name);
        await tester.enterText(find.byType(TextField).at(1), newAlias.command);
        await tester.tap(find.byKey(Key('add_alias_button')));
        await tester.pumpAndSettle();

        verify(() => shellAliasSource.addAlias(newAlias)).called(1);
      });

      testWidgets('deleteAlias when delete button is pressed', (tester) async {
        when(() => shellAliasSource.getAliases()).thenAnswer(
          (_) async => [Alias(name: 'aliasToDelete', command: 'command')],
        );
        when(
          () => shellAliasSource.deleteAlias(any()),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: AliasListScreen(
              gitAliasSource: gitAliasSource,
              shellAliasSource: shellAliasSource,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('aliasToDelete'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        verify(() => shellAliasSource.deleteAlias('aliasToDelete')).called(1);
      });
    });
  });
}
