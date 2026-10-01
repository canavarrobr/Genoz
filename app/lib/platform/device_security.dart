// Recursos de segurança do aparelho: biometria do sistema e proteção de tela.
// No navegador nenhum dos dois existe; as opções somem da tela de Ajustes.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class Biometrics {
  /// Há biometria cadastrada e utilizável neste aparelho?
  Future<bool> available();

  /// Pede a digital/rosto. `false` se cancelada, falhou ou não está disponível.
  Future<bool> authenticate(String reason);
}

class SystemBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  bool get _supportedPlatform =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<bool> available() async {
    if (!_supportedPlatform) return false;
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    if (!_supportedPlatform) return false;
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } catch (_) {
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((ref) => SystemBiometrics());

/// `FLAG_SECURE` no Android: bloqueia capturas de tela e esconde o conteúdo
/// na lista de apps recentes.
abstract final class SecureScreen {
  static const _channel = MethodChannel('genoz/janela');

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> set(bool on) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('setSecure', on);
    } on MissingPluginException {
      // Testes de widget: não há Android do outro lado.
    }
  }
}
