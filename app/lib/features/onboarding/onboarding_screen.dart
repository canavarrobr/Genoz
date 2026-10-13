// Apresentação inicial (Módulo 13): o que o Genoz faz, tudo fica no aparelho, não é diagnóstico.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../persistence/project_repository.dart';
import '../../ui/brand.dart';
import '../import/import_controller.dart';
import '../settings/settings.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  /// `again`: aberta pela tela Sobre (ao terminar, só volta).
  const OnboardingScreen({super.key, this.again = false});
  final bool again;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (widget.again) {
      Navigator.of(context).pop();
      return;
    }
    await ref.read(settingsProvider.notifier).setOnboardingDone();
  }

  /// Cria um projeto de exemplo, gera o VCF fictício e abre o projeto.
  Future<void> _demo() async {
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    // Tudo o que vem do `ref` e do `context` antes: ao terminar, esta tela sai da árvore.
    final router = GoRouter.maybeOf(context);
    final importer = ref.read(importControllerProvider.notifier);
    final navigator = Navigator.of(context);
    final project = await ref.read(projectRepositoryProvider).createProject(l.obDemoProject);
    if (widget.again) {
      navigator.pop();
    } else {
      await ref.read(settingsProvider.notifier).setOnboardingDone();
    }
    router?.push('/projeto/${project.id}');
    await importer.importSyntheticExample(project.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final pages = [
      (Icons.compare_arrows, l.ob1Title, l.ob1Body),
      (Icons.lock_outline, l.ob2Title, l.ob2Body),
      (Icons.school_outlined, l.ob3Title, l.ob3Body),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _busy ? null : _finish, child: Text(l.obSkip)),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: GenozLogo(size: 28, showSignature: true)),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final (icon, title, body) in pages)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 24),
                          Text(title, style: t.headlineSmall, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          Text(body, style: t.bodyLarge, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Semantics(
              label: '${_page + 1} / ${pages.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.all(4),
                      width: i == _page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : last
                            ? _finish
                            : () => _pages.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                    child: Text(last ? l.obStart : l.obNext),
                  ),
                  if (last) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _demo,
                      icon: const Icon(Icons.science_outlined),
                      label: Text(l.obDemo),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
