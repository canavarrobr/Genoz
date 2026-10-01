// Ajustes do app, guardados num pequeno arquivo JSON no armazenamento privado
// (pasta do app no celular, OPFS no navegador) — nunca na nuvem.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../persistence/app_storage.dart';
import '../../platform/blob_store.dart';
import 'pin.dart';

const settingsFile = 'ajustes.json';

/// Tempos em segundo plano depois dos quais o app pede o PIN de novo.
const lockDelayOptions = [60, 300, 900];

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.pin,
    this.biometrics = false,
    this.secureScreen = false,
    this.lockAfterSeconds = 60,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final ThemeMode themeMode;

  /// `pt`, `en` ou `null` (idioma do sistema).
  final String? locale;
  final PinHash? pin;
  final bool biometrics;
  final bool secureScreen;
  final int lockAfterSeconds;

  /// Tentativas erradas seguidas de PIN (persistidas: fechar o app não zera a espera).
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool get lockEnabled => pin != null;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? Function()? locale,
    PinHash? Function()? pin,
    bool? biometrics,
    bool? secureScreen,
    int? lockAfterSeconds,
    int? failedAttempts,
    DateTime? Function()? lockedUntil,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: locale != null ? locale() : this.locale,
    pin: pin != null ? pin() : this.pin,
    biometrics: biometrics ?? this.biometrics,
    secureScreen: secureScreen ?? this.secureScreen,
    lockAfterSeconds: lockAfterSeconds ?? this.lockAfterSeconds,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: lockedUntil != null ? lockedUntil() : this.lockedUntil,
  );

  Map<String, Object?> toJson() => {
    'schema': 1,
    'theme': themeMode.name,
    'locale': locale,
    'pin': pin?.toJson(),
    'biometrics': biometrics,
    'secure_screen': secureScreen,
    'lock_after_seconds': lockAfterSeconds,
    'failed_attempts': failedAttempts,
    'locked_until': lockedUntil?.toUtc().toIso8601String(),
  };

  /// Lê o JSON tolerando campos ausentes ou inválidos (volta ao padrão de cada um).
  factory AppSettings.fromJson(Map<String, Object?> j) {
    T? as<T>(Object? v) => v is T ? v : null;
    final theme = ThemeMode.values.where((m) => m.name == j['theme']).firstOrNull;
    final locale = as<String>(j['locale']);
    final delay = as<int>(j['lock_after_seconds']);
    return AppSettings(
      themeMode: theme ?? ThemeMode.system,
      locale: locale == 'pt' || locale == 'en' ? locale : null,
      pin: PinHash.fromJson(j['pin']),
      biometrics: as<bool>(j['biometrics']) ?? false,
      secureScreen: as<bool>(j['secure_screen']) ?? false,
      lockAfterSeconds: lockDelayOptions.contains(delay) ? delay! : 60,
      failedAttempts: as<int>(j['failed_attempts']) ?? 0,
      lockedUntil: DateTime.tryParse(as<String>(j['locked_until']) ?? ''),
    );
  }

  static Future<AppSettings> load(BlobStore blobs) async {
    try {
      if (!await blobs.exists(settingsFile)) return const AppSettings();
      final json = jsonDecode(await blobs.readString(settingsFile));
      return json is Map<String, Object?> ? AppSettings.fromJson(json) : const AppSettings();
    } catch (_) {
      return const AppSettings();
    }
  }
}

/// Ajustes lidos em `main()` antes de abrir o app (tema e bloqueio valem desde o primeiro quadro).
final initialSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  BlobStore get _blobs => ref.read(appStorageProvider).blobs;

  Future<void> _save(AppSettings next) async {
    state = next;
    await _blobs.writeBytes(settingsFile, Uint8List.fromList(utf8.encode(jsonEncode(next.toJson()))));
  }

  Future<void> setThemeMode(ThemeMode mode) => _save(state.copyWith(themeMode: mode));

  Future<void> setLocale(String? locale) => _save(state.copyWith(locale: () => locale));

  Future<void> setSecureScreen(bool on) => _save(state.copyWith(secureScreen: on));

  Future<void> setLockAfter(int seconds) => _save(state.copyWith(lockAfterSeconds: seconds));

  Future<void> setBiometrics(bool on) => _save(state.copyWith(biometrics: on && state.lockEnabled));

  /// Define (ou troca) o PIN. Zera as tentativas erradas.
  Future<void> setPin(String pin) =>
      _save(state.copyWith(pin: () => PinHash.create(pin), failedAttempts: 0, lockedUntil: () => null));

  /// Desliga o bloqueio (e a biometria, que depende dele).
  Future<void> removePin() =>
      _save(state.copyWith(pin: () => null, biometrics: false, failedAttempts: 0, lockedUntil: () => null));

  /// Confere o PIN, registrando acertos e erros. Devolve `true` se conferiu.
  /// Durante a espera ([AppSettings.lockedUntil] no futuro) sempre devolve `false`.
  Future<bool> checkPin(String pin, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    final until = state.lockedUntil;
    if (until != null && t.isBefore(until)) return false;
    if (state.pin?.matches(pin) ?? false) {
      if (state.failedAttempts != 0 || until != null) {
        await _save(state.copyWith(failedAttempts: 0, lockedUntil: () => null));
      }
      return true;
    }
    final failed = state.failedAttempts + 1;
    final wait = lockoutFor(failed);
    await _save(state.copyWith(failedAttempts: failed, lockedUntil: () => wait == Duration.zero ? null : t.add(wait)));
    return false;
  }

  /// Volta tudo ao padrão (usado por "Apagar todos os dados").
  Future<void> reset() async {
    state = const AppSettings();
    await _blobs.deleteFile(settingsFile);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
