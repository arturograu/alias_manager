import 'package:alias_manager/data/alias_service/alias_service.dart'
    as alias_service;

enum AliasType {
  shell,
  git;

  bool get isShell => this == AliasType.shell;
  bool get isGit => this == AliasType.git;
}

final class Alias {
  final String name;
  final String command;
  final AliasType type;

  const Alias({required this.name, required this.command, required this.type});

  factory Alias.fromSourceAlias(
    alias_service.Alias alias, {
    required AliasType type,
  }) {
    return Alias(name: alias.name, command: alias.command, type: type);
  }

  alias_service.Alias toSourceAlias() {
    return alias_service.Alias(name: name, command: command);
  }
}
