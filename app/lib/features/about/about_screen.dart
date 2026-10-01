import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/genoz_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/brand.dart';
import '../../ui/privacy_chip.dart';
import '../../ui/theme.dart';

/// Versão do app (a mesma de pubspec.yaml).
const appVersion = '0.7.0';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final pillars = [
      (Icons.biotech_outlined, l.pillarScience, l.pillarScienceBody),
      (Icons.shield_outlined, l.pillarPrivacy, l.pillarPrivacyBody),
      (Icons.bolt_outlined, l.pillarPerformance, l.pillarPerformanceBody),
      (Icons.devices_outlined, l.pillarMultiplatform, l.pillarMultiplatformBody),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.aboutTitle)),
      drawer: const GenozDrawer(current: '/sobre'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(color: GenozColors.deep, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                const GenozLogo(size: 38, showSignature: true, onDark: true),
                const SizedBox(height: 20),
                Text(
                  l.brandSplash.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(l.brandSlogan, style: t.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Text(l.aboutBody)),
          for (final (icon, title, body) in pillars)
            Card(
              child: ListTile(
                leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                title: Text(title, style: t.titleMedium),
                subtitle: Text(body),
              ),
            ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l.privacyTitle),
            onTap: () => showPrivacyDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.aboutLicenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Genoz',
              applicationVersion: appVersion,
              applicationIcon: const Padding(padding: EdgeInsets.all(8), child: GenozSymbol(height: 48)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Text(
              '${l.aboutVersion(appVersion, ref.watch(genozCoreProvider).coreVersion)}\n${l.aboutSource}\n\n${l.notDiagnosis}',
              style: t.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
