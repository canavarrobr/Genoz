// Componentes da identidade visual (docs/estilo/GUIA_DE_ESTILO.md).

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'privacy_chip.dart';
import 'theme.dart';

/// Símbolo do Genoz (dupla hélice em "S"), gerado por tools/marca/gerar_marca.py.
class GenozSymbol extends StatelessWidget {
  const GenozSymbol({super.key, this.height = 40, this.semanticLabel, this.onDark});
  final double height;
  final String? semanticLabel;

  /// Versão com fitas mais claras, para fundos escuros (padrão: segue o tema).
  final bool? onDark;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    (onDark ?? Theme.of(context).brightness == Brightness.dark)
        ? 'assets/marca/simbolo_escuro.svg'
        : 'assets/marca/simbolo.svg',
    height: height,
    semanticsLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
  );
}

/// Símbolo + "Genoz" (+ assinatura opcional), como no logo do guia.
class GenozLogo extends StatelessWidget {
  const GenozLogo({super.key, this.size = 32, this.showSignature = false, this.onDark});
  final double size;
  final bool showSignature;

  /// Texto claro (sobre azul profundo ou gradiente). Padrão: segue o tema.
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    final color = dark ? Colors.white : GenozColors.deep;
    return Semantics(
      container: true,
      image: true,
      label: 'Genoz',
      child: ExcludeSemantics(
        // Em telas estreitas (ou fonte grande) o logo encolhe em vez de estourar.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GenozSymbol(height: size * (showSignature ? 1.9 : 1.25), onDark: dark),
              SizedBox(width: size * 0.35),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genoz',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: size,
                      height: 1.0,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (showSignature) ...[
                    SizedBox(height: size * 0.18),
                    Text(
                      l.brandSignature,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: size * 0.26,
                        letterSpacing: size * 0.08,
                        color: dark ? Colors.white70 : GenozColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho com o gradiente principal, logo e slogan (tela inicial).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(gradient: GenozColors.headerGradient, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GenozLogo(size: 30, showSignature: true, onDark: true),
          const SizedBox(height: 14),
          Text(
            l.brandSlogan,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const PrivacyChip(onDark: true),
        ],
      ),
    );
  }
}

/// Menu lateral no estilo da referência: azul profundo, item ativo em azul-petróleo.
class GenozDrawer extends StatelessWidget {
  const GenozDrawer({super.key, required this.current});

  /// Rota atual (`/`, `/sobre`...), para destacar o item ativo.
  final String current;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget item(IconData icon, String label, String route, {void Function(BuildContext)? action}) {
      final active = action == null && current == route;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: active ? GenozColors.petroleum : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(icon, color: Colors.white),
            title: Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            selected: active,
            onTap: () {
              // O contexto do menu some ao fechá-lo; o do Navigator continua ativo.
              final navContext = Navigator.of(context).context;
              final router = GoRouter.maybeOf(context);
              Navigator.pop(context);
              if (action != null) {
                action(navContext);
              } else if (!active) {
                router?.go(route);
              }
            },
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: GenozColors.deep,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 24), child: GenozLogo(size: 28, onDark: true)),
            item(Icons.folder_outlined, l.menuProjects, '/'),
            item(Icons.school_outlined, l.learnTitle, '/aprender'),
            item(Icons.local_library_outlined, l.annotTitle, '/anotacoes'),
            item(Icons.info_outline, l.menuAbout, '/sobre'),
            item(Icons.verified_user_outlined, l.privacyCheckTitle, '/privacidade'),
            item(Icons.settings_outlined, l.settingsTitle, '/ajustes'),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.notDiagnosis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio com o símbolo da marca.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: 0.9, child: const GenozSymbol(height: 72)),
          const SizedBox(height: 16),
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            body,
            style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
