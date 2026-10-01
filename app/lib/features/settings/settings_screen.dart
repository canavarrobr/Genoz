import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../platform/device_security.dart';
import '../../ui/brand.dart';
import '../../ui/theme.dart';
import 'lock.dart';
import 'settings.dart';
import 'wipe.dart';

final biometricsAvailableProvider = FutureProvider<bool>((ref) => ref.watch(biometricsProvider).available());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    final bioAvailable = ref.watch(biometricsAvailableProvider).value ?? false;
    final t = Theme.of(context).textTheme;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(title, style: t.titleSmall),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      drawer: const GenozDrawer(current: '/ajustes'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          section(l.settingsAppearance),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settingsTheme),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: ThemeMode.system, label: Text(l.settingsSystem)),
                      ButtonSegment(value: ThemeMode.light, label: Text(l.settingsLight)),
                      ButtonSegment(value: ThemeMode.dark, label: Text(l.settingsDark)),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => c.setThemeMode(v.single),
                  ),
                  const SizedBox(height: 16),
                  Text(l.settingsLanguage),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: '', label: Text(l.settingsSystem)),
                      const ButtonSegment(value: 'pt', label: Text('Português')),
                      const ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {s.locale ?? ''},
                    onSelectionChanged: (v) => c.setLocale(v.single.isEmpty ? null : v.single),
                  ),
                ],
              ),
            ),
          ),
          section(l.settingsLock),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: Text(l.settingsPinLock),
                  subtitle: Text(s.lockEnabled ? l.settingsPinOn : l.settingsPinOff),
                  value: s.lockEnabled,
                  onChanged: (on) async {
                    if (on) {
                      final pin = await PinSetupScreen.create(context);
                      if (pin != null) await c.setPin(pin);
                    } else if (await PinSetupScreen.verify(context)) {
                      await c.removePin();
                    }
                  },
                ),
                if (s.lockEnabled) ...[
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: Text(l.settingsChangePin),
                    onTap: () async {
                      if (!await PinSetupScreen.verify(context) || !context.mounted) return;
                      final pin = await PinSetupScreen.create(context);
                      if (pin != null) await c.setPin(pin);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(l.settingsLockAfter),
                    trailing: DropdownButton<int>(
                      value: s.lockAfterSeconds,
                      underline: const SizedBox.shrink(),
                      items: [
                        for (final sec in lockDelayOptions)
                          DropdownMenuItem(value: sec, child: Text(l.minutes(sec ~/ 60))),
                      ],
                      onChanged: (v) => v == null ? null : c.setLockAfter(v),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: Text(l.settingsBiometrics),
                    subtitle: bioAvailable ? null : Text(l.settingsBiometricsUnavailable),
                    value: s.biometrics && bioAvailable,
                    onChanged: bioAvailable
                        ? (on) async {
                            // Liga só depois de uma leitura bem-sucedida.
                            if (on && !await ref.read(biometricsProvider).authenticate(l.lockBiometricReason)) return;
                            await c.setBiometrics(on);
                          }
                        : null,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: context.palette.info),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.settingsLockNote, style: t.bodySmall)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (SecureScreen.supported) ...[
            section(l.settingsScreen),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.screenshot_monitor_outlined),
                title: Text(l.settingsSecureScreen),
                subtitle: Text(l.settingsSecureScreenHint),
                value: s.secureScreen,
                onChanged: c.setSecureScreen,
              ),
            ),
          ],
          section(l.settingsData),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: context.palette.error),
              title: Text(l.wipeTitle, style: TextStyle(color: context.palette.error)),
              subtitle: Text(l.wipeSubtitle),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const WipeScreen())),
            ),
          ),
        ],
      ),
    );
  }
}

class WipeScreen extends ConsumerWidget {
  const WipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.wipeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.warning_amber_rounded, size: 48, color: context.palette.error),
          const SizedBox(height: 12),
          Text(l.wipeBody),
          const SizedBox(height: 20),
          WipeConfirmField(
            onConfirmed: () async {
              await wipeAllData(ref);
              ref.invalidate(lockProvider);
              if (!context.mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              context.go('/');
              messenger.showSnackBar(SnackBar(content: Text(l.wipeDone)));
            },
          ),
        ],
      ),
    );
  }
}

/// Telas de PIN usadas pelos Ajustes: criar (digitar duas vezes) ou conferir o atual.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen._({required this.verifyOnly});
  final bool verifyOnly;

  /// Devolve o novo PIN (já confirmado) ou `null` se cancelado.
  static Future<String?> create(BuildContext context) =>
      Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => const PinSetupScreen._(verifyOnly: false)));

  /// Pede o PIN atual. `true` se conferiu.
  static Future<bool> verify(BuildContext context) async =>
      await Navigator.of(context)
          .push<String>(MaterialPageRoute(builder: (_) => const PinSetupScreen._(verifyOnly: true))) !=
      null;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;
  String _message = '';
  // Muda a chave para recriar o teclado (limpo) entre os passos.
  int _step = 0;

  Future<bool> _submit(String pin) async {
    final l = AppLocalizations.of(context);
    if (widget.verifyOnly) {
      final ok = await ref.read(settingsProvider.notifier).checkPin(pin);
      if (!mounted) return ok;
      if (ok) {
        Navigator.of(context).pop(pin);
      } else {
        setState(() => _message = l.lockWrongPin);
      }
      return ok;
    }
    if (_first == null) {
      setState(() {
        _first = pin;
        _message = '';
        _step++;
      });
      return true;
    }
    if (pin == _first) {
      Navigator.of(context).pop(pin);
      return true;
    }
    setState(() {
      _first = null;
      _message = l.pinMismatch;
      _step++;
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final wait = s.lockedUntil?.difference(DateTime.now()) ?? Duration.zero;
    final title = widget.verifyOnly ? l.pinCurrent : (_first == null ? l.pinNew : l.pinRepeat);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsPinLock)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              if (!widget.verifyOnly) ...[
                const SizedBox(height: 4),
                Text(l.pinRule, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 16),
              PinPad(
                key: ValueKey(_step),
                onSubmit: _submit,
                enabled: !(widget.verifyOnly && wait > Duration.zero),
                message: widget.verifyOnly && wait > Duration.zero ? l.lockWait(wait.inSeconds + 1) : _message,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
