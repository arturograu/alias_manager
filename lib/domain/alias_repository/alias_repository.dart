import 'package:alias_manager/data/alias_service/git_alias_service.dart';
import 'package:alias_manager/data/alias_service/shell_alias_service.dart';
import 'package:alias_manager/domain/alias_repository/models/models.dart';
import 'package:rxdart/subjects.dart';

class AliasRepository {
  AliasRepository({
    required GitAliasSource gitAliasSource,
    required ShellAliasSource shellAliasSource,
  }) : _gitAliasSource = gitAliasSource,
       _shellAliasSource = shellAliasSource;

  final ShellAliasSource _shellAliasSource;
  final GitAliasSource _gitAliasSource;

  final _aliasesSubject = BehaviorSubject.seeded(<Alias>[]);

  Stream<List<Alias>> get aliases => _aliasesSubject.stream;

  Future<List<Alias>> fetchAliases() async {
    final gitAliases = await _gitAliasSource.getAliases();
    final shellAliases = await _shellAliasSource.getAliases();
    final aliases = [
      ...gitAliases.map((e) => Alias.fromSourceAlias(e, type: AliasType.git)),
      ...shellAliases.map(
        (e) => Alias.fromSourceAlias(e, type: AliasType.shell),
      ),
    ];
    _aliasesSubject.add(aliases);
    return aliases;
  }

  Future<void> addAlias(Alias alias, AliasType aliasType) async {
    final sourceAlias = alias.toSourceAlias();
    await switch (aliasType) {
      AliasType.shell => _shellAliasSource.addAlias(sourceAlias),
      AliasType.git => _gitAliasSource.addAlias(sourceAlias),
    };
    _aliasesSubject.add([..._aliasesSubject.value, alias]);
  }

  Future<void> deleteAlias(String name, AliasType aliasType) async {
    await switch (aliasType) {
      AliasType.shell => _shellAliasSource.deleteAlias(name),
      AliasType.git => _gitAliasSource.deleteAlias(name),
    };
    final aliases = _aliasesSubject.value.where((a) => a.name != name).toList();
    _aliasesSubject.add(aliases);
  }
}
