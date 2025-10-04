import 'package:alias_manager/sources/git_alias_source.dart';
import 'package:alias_manager/sources/shell_alias_source.dart';
import 'package:alias_manager/view/alias_list_screen.dart';
import 'package:alias_manager/view/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MainApp(
      gitAliasSource: GitAliasSource(),
      shellAliasSource: ShellAliasSource(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({
    super.key,
    required this.shellAliasSource,
    required this.gitAliasSource,
  });

  final GitAliasSource gitAliasSource;
  final ShellAliasSource shellAliasSource;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alias Manager',
      theme: appTheme,
      themeMode: ThemeMode.light,
      home: AliasListScreen(
        shellAliasSource: shellAliasSource,
        gitAliasSource: gitAliasSource,
      ),
    );
  }
}
