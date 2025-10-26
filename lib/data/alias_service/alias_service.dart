import 'package:equatable/equatable.dart';

class Alias extends Equatable {
  final String name;
  final String command;

  const Alias({required this.name, required this.command});

  @override
  List<Object?> get props => [name, command];
}

abstract class AliasSource {
  Future<void> addAlias(Alias alias);
  Future<List<Alias>> getAliases();
  Future<void> deleteAlias(String name);
}
