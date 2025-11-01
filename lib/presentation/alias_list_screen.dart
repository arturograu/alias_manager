import 'package:alias_manager/data/alias_service/alias_service.dart';
import 'package:alias_manager/main.dart';
import 'package:alias_manager/presentation/alias_form.dart';
import 'package:alias_manager/presentation/alias_list.dart';
import 'package:alias_manager/presentation/alias_type_selector.dart';
import 'package:alias_manager/presentation/app_main_bar.dart';
import 'package:alias_manager/presentation/app_theme.dart';
import 'package:alias_manager/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AliasListScreen extends ConsumerStatefulWidget {
  const AliasListScreen({super.key});

  @override
  ConsumerState<AliasListScreen> createState() => _AliasListScreenState();
}

class _AliasListScreenState extends ConsumerState<AliasListScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _commandController = TextEditingController();
  late AnimationController _fadeInController;

  bool _isLoading = false;
  List<Alias> _aliases = [];
  AliasType _selectedType = AliasType.shell;

  AliasSource get _currentSource => _selectedType.isShell
      ? ref.read(shellAliasServiceProvider)
      : ref.read(gitAliasServiceProvider);

  Future<void> _loadAliases() async {
    try {
      await _fadeInController.reverse();
      setState(() {
        _isLoading = true;
      });
      final aliases = await _currentSource.getAliases();
      setState(() {
        _aliases = aliases;
        _isLoading = false;
      });
      await _fadeInController.forward();
    } catch (e) {
      await _fadeInController.forward();
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load aliases: $e')));
    }
  }

  Future<void> _addAlias() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    final command = _commandController.text.trim();

    if (name.isEmpty || command.isEmpty) return;

    final alias = Alias(name: name, command: command);

    try {
      setState(() {
        _isLoading = true;
      });
      await _currentSource.addAlias(alias);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save alias: $e')));
    }

    setState(() {
      _aliases.add(Alias(name: name, command: command));
      _nameController.clear();
      _commandController.clear();
    });
  }

  Future<void> _deleteAlias(String name) async {
    await _currentSource.deleteAlias(name);
    setState(() {
      _aliases.removeWhere((alias) => alias.name == name);
    });
  }

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadAliases();
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            AppMainBar(
              child: AliasTypeSelector(
                selectedType: _selectedType,
                onChanged: (type) async {
                  setState(() {
                    _selectedType = type;
                  });
                  await _loadAliases();
                },
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: AppLayoutWrapper(
                child: AppCard(
                  child: Column(
                    children: [
                      AppInnerCard(
                        child: AliasForm(
                          nameHint: _selectedType.isShell ? 'll' : 'lg',
                          commandHint: _selectedType.isShell
                              ? 'ls -alF'
                              : 'log --oneline',
                          nameController: _nameController,
                          commandController: _commandController,
                          onAddAlias: _addAlias,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: AppInnerCard(
                          child: FadeTransition(
                            opacity: _fadeInController,
                            child: AliasList(
                              aliases: _aliases,
                              selectedType: _selectedType,
                              onDeleteAlias: _deleteAlias,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
