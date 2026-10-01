// Bloqueio do app: tela de PIN/biometria ao abrir e ao voltar depois de um
// tempo em segundo plano. O conteúdo por baixo continua vivo (nada se perde),
// só fica escondido e inacessível.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../platform/device_security.dart';
import '../../ui/brand.dart';
import '../../ui/theme.dart';
import 'pin.dart';
import 'settings.dart';
import 'wipe.dart';

class LockController extends Notifier<bool> {
  DateTime? _hiddenAt;

  /// Relógio substituível nos testes.
  DateTime Function() clock = DateTime.now;

  /// `true` = bloqueado. Começa bloqueado se houver PIN.
  @override
  bool build() => ref.read(settingsProvider).lockEnabled;

  void unlock() => state = false;

  void appHidden() => _hiddenAt ??= clock();

  void appResumed() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    final s = ref.read(settingsProvider);
    if (!s.lockEnabled || hiddenAt == null) return;
    if (clock().difference(hiddenAt).inSeconds >= s.lockAfterSeconds) state = true;
  }
}

final lockProvider = NotifierProvider<LockController, bool>(LockController.new);

/// Envolve o app inteiro (`MaterialApp.builder`).
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(lockProvider.notifier).appHidden(),
      onResume: () => ref.read(lockProvider.notifier).appResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(lockProvider) && ref.watch(settingsProvider).lockEnabled;
    return Stack(
      fit: StackFit.expand,
      children: [
        // O app fica montado (estado preservado), mas invisível e fora da acessibilidade.
        Visibility(
          visible: !locked,
          maintainState: true,
          child: ExcludeSemantics(excluding: locked, child: widget.child),
        ),
        if (locked)
          // A tela de bloqueio fica fora do Navigator do app: precisa do próprio Overlay.
          Overlay(initialEntries: [OverlayEntry(builder: (_) => const LockScreen())]),
      ],
    );
  }
}

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _message = '';
  bool _forgot = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && ref.read(settingsProvider).lockedUntil != null) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _tryBiometrics() async {
    if (!mounted || !ref.read(settingsProvider).biometrics) return;
    final ok = await ref.read(biometricsProvider).authenticate(AppLocalizations.of(context).lockBiometricReason);
    if (ok && mounted) ref.read(lockProvider.notifier).unlock();
  }

  Future<bool> _submit(String pin) async {
    final l = AppLocalizations.of(context);
    final ok = await ref.read(settingsProvider.notifier).checkPin(pin);
    if (!mounted) return ok;
    if (ok) {
      ref.read(lockProvider.notifier).unlock();
    } else {
      setState(() => _message = l.lockWrongPin);
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final until = settings.lockedUntil;
    final wait = until == null ? Duration.zero : until.difference(DateTime.now());
    final waiting = wait > Duration.zero;
    // Ícones claros na barra de status (fundo azul profundo).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: GenozColors.deep,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _forgot
                    ? _ForgotPin(onBack: () => setState(() => _forgot = false))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GenozSymbol(height: 56, onDark: true),
                          const SizedBox(height: 16),
                          Text(
                            l.lockTitle,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          PinPad(
                            onDark: true,
                            enabled: !waiting,
                            onSubmit: _submit,
                            message: waiting ? l.lockWait(wait.inSeconds + 1) : _message,
                          ),
                          if (settings.biometrics) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _tryBiometrics,
                              style: TextButton.styleFrom(foregroundColor: Colors.white),
                              icon: const Icon(Icons.fingerprint),
                              label: Text(l.lockUseBiometrics),
                            ),
                          ],
                          TextButton(
                            onPressed: () => setState(() => _forgot = true),
                            style: TextButton.styleFrom(foregroundColor: Colors.white70),
                            child: Text(l.lockForgot),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Esqueci o PIN": a única saída é apagar tudo (o PIN não pode ser recuperado).
class _ForgotPin extends ConsumerWidget {
  const _ForgotPin({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    const white = TextStyle(color: Colors.white);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.lockForgot, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
        const SizedBox(height: 12),
        Text(l.lockForgotBody, style: white),
        const SizedBox(height: 20),
        WipeConfirmField(
          onDark: true,
          onConfirmed: () async {
            await wipeAllData(ref);
            ref.read(lockProvider.notifier).unlock();
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onBack,
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: Text(l.lockBack),
        ),
      ],
    );
  }
}

/// Teclado numérico com bolinhas. Aceita também o teclado físico (Web/emulador).
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onSubmit, this.message = '', this.enabled = true, this.onDark = false});

  /// Devolve `true` se o PIN foi aceito (senão o campo é limpo).
  final Future<bool> Function(String pin) onSubmit;
  final String message;
  final bool enabled;
  final bool onDark;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _digit(String d) {
    if (!widget.enabled || _busy || _pin.length >= pinMaxLength) return;
    setState(() => _pin += d);
  }

  void _back() {
    if (_pin.isEmpty || _busy) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _ok() async {
    if (!widget.enabled || _busy || !isValidPin(_pin)) return;
    setState(() => _busy = true);
    final accepted = await widget.onSubmit(_pin);
    if (mounted) {
      setState(() {
        _busy = false;
        if (!accepted) _pin = '';
      });
    }
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final ch = e.character;
    if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
      _digit(ch);
    } else if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _back();
    } else if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _ok();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fg = widget.onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final accent = widget.onDark ? GenozColors.cyan : Theme.of(context).colorScheme.primary;
    Widget key(String label, {VoidCallback? onTap, IconData? icon, String? semantics}) => Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 56,
        child: TextButton(
          onPressed: widget.enabled && !_busy ? onTap : null,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          child: icon != null ? Icon(icon, semanticLabel: semantics) : Text(label),
        ),
      ),
    );
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: l.pinDigitsEntered(_pin.length),
            child: SizedBox(
              height: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < (_pin.length < pinMinLength ? pinMinLength : _pin.length); i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length ? accent : Colors.transparent,
                        border: Border.all(color: accent, width: 2),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: Center(
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.onDark ? const Color(0xFFFFC9C6) : Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (final d in row) key(d, onTap: () => _digit(d))],
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              key('', icon: Icons.backspace_outlined, onTap: _back, semantics: l.pinErase),
              key('0', onTap: () => _digit('0')),
              key('', icon: Icons.check_circle, onTap: isValidPin(_pin) ? _ok : null, semantics: l.pinConfirm),
            ],
          ),
        ],
      ),
    );
  }
}
