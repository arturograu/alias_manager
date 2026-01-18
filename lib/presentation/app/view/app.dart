import 'package:alias_manager/presentation/app/theme/app_theme.dart';
import 'package:alias_manager/presentation/home/alias_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alias Manager',
      theme: appTheme,
      themeMode: ThemeMode.light,
      home: AliasListPage(),
    );
  }
}
