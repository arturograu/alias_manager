import 'package:alias_manager/data/alias_service/git_alias_service.dart';
import 'package:alias_manager/data/alias_service/shell_alias_service.dart';
import 'package:alias_manager/presentation/alias_list_screen.dart';
import 'package:alias_manager/presentation/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gitAliasServiceProvider = Provider<GitAliasSource>((ref) {
  return GitAliasSource();
});

final shellAliasServiceProvider = Provider<ShellAliasSource>((ref) {
  return ShellAliasSource();
});

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Alias Manager',
      theme: appTheme,
      themeMode: ThemeMode.light,
      home: const AliasListScreen(),
    );
  }
}
