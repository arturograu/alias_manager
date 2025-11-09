import 'package:alias_manager/data/alias_service/git_alias_service.dart';
import 'package:alias_manager/data/alias_service/shell_alias_service.dart';
import 'package:alias_manager/presentation/app/view/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gitAliasServiceProvider = Provider<GitAliasSource>((ref) {
  return GitAliasSource();
});

final shellAliasServiceProvider = Provider<ShellAliasSource>((ref) {
  return ShellAliasSource();
});

void main() {
  runApp(ProviderScope(child: App()));
}
