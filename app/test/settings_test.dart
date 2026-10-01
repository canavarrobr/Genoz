import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genoz/core/genoz_core.dart';
import 'package:genoz/features/settings/lock.dart';
import 'package:genoz/features/settings/pin.dart';
import 'package:genoz/features/settings/settings.dart';
import 'package:genoz/features/settings/settings_screen.dart';
import 'package:genoz/features/settings/wipe.dart';
import 'package:genoz/l10n/generated/app_localizations.dart';
import 'package:genoz/persistence/app_storage.dart';
import 'package:genoz/persistence/database.dart';
import 'package:genoz/persistence/project_repository.dart';
import 'package:genoz/platform/device_security.dart';
import 'package:genoz/ui/theme.dart';

import 'support.dart';

class FakeBiometrics implements Biometrics {
  FakeBiometrics({this.isAvailable = true, this.succeed = true});
  bool isAvailable;
  bool succeed;
  int calls = 0;

  @override
  Future<bool> available() async => isAvailable;

  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return succeed;
  }
}

/// App mínimo com o LockGate, como no `MaterialApp.builder` do Genoz.
Widget _gated(ProviderContainer container, {Widget? home}) => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: genozTheme(Brightness.light),
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => LockGate(child: child!),
        home: home ?? const Scaffold(body: Text('conteúdo do app')),
      ),
    );

ProviderContainer _container({AppSettings settings = const AppSettings(), Biometrics? bio, MemoryBlobStore? blobs}) =>
    ProviderContainer(overrides: [
      appStorageProvider.overrideWithValue(AppStorage(blobs ?? MemoryBlobStore())),
      initialSettingsProvider.overrideWithValue(settings),
      biometricsProvider.overrideWithValue(bio ?? FakeBiometrics(isAvailable: false)),
      genozCoreProvider.overrideWithValue(FakeGenozCore()),
    ]);

Future<void> _typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.widgetWithText(TextButton, d));
    await tester.pump();
  }
  await tester.tap(find.bySemanticsLabel('Confirmar'));
  await tester.pumpAndSettle();
}

void main() {
  group('PIN', () {
    test('hash confere com o PIN certo e não com outro; sal muda a cada definição', () {
      final a = PinHash.create('2580', iterations: 1000);
      final b = PinHash.create('2580', iterations: 1000);
      expect(a.matches('2580'), isTrue);
      expect(a.matches('2581'), isFalse);
      expect(a.salt, isNot(b.salt));
      expect(a.hash, isNot(b.hash));
      expect(a.toJson().toString(), isNot(contains('2580')), reason: 'o PIN nunca é guardado');
    });

    test('PBKDF2-HMAC-SHA256 confere com o vetor de teste (RFC 7914, 1 iteração)', () {
      final out = pbkdf2('passwd', 'salt'.codeUnits, 1);
      expect(out.sublist(0, 8), [0x55, 0xac, 0x04, 0x6e, 0x56, 0xe3, 0x08, 0x9f]);
    });

    test('só aceita 4 a 8 dígitos', () {
      expect(isValidPin('123'), isFalse);
      expect(isValidPin('1234'), isTrue);
      expect(isValidPin('12345678'), isTrue);
      expect(isValidPin('123456789'), isFalse);
      expect(isValidPin('12a4'), isFalse);
    });

    test('espera cresce depois de 5 erros e para em 15 min', () {
      expect(lockoutFor(4), Duration.zero);
      expect(lockoutFor(5), const Duration(seconds: 30));
      expect(lockoutFor(6), const Duration(minutes: 1));
      expect(lockoutFor(7), const Duration(minutes: 2));
      expect(lockoutFor(40), const Duration(minutes: 15));
    });
  });

  group('ajustes', () {
    test('persistem e são relidos; JSON inválido volta ao padrão', () async {
      final blobs = MemoryBlobStore();
      final c = _container(blobs: blobs);
      final ctl = c.read(settingsProvider.notifier);
      await ctl.setThemeMode(ThemeMode.dark);
      await ctl.setLocale('en');
      await ctl.setPin('2580');
      await ctl.setLockAfter(300);
      await ctl.setSecureScreen(true);

      final again = await AppSettings.load(blobs);
      expect(again.themeMode, ThemeMode.dark);
      expect(again.locale, 'en');
      expect(again.lockAfterSeconds, 300);
      expect(again.secureScreen, isTrue);
      expect(again.pin!.matches('2580'), isTrue);

      await blobs.writeBytes(settingsFile, Uint8List.fromList('{quebrado'.codeUnits));
      expect((await AppSettings.load(blobs)).lockEnabled, isFalse);
      c.dispose();
    });

    test('erros de PIN geram espera; durante a espera nem o PIN certo entra', () async {
      final c = _container();
      final ctl = c.read(settingsProvider.notifier);
      await ctl.setPin('2580');
      final t0 = DateTime(2026, 10, 1, 12);
      for (var i = 0; i < 5; i++) {
        expect(await ctl.checkPin('0000', now: t0), isFalse);
      }
      expect(c.read(settingsProvider).lockedUntil, t0.add(const Duration(seconds: 30)));
      expect(await ctl.checkPin('2580', now: t0.add(const Duration(seconds: 10))), isFalse);
      expect(await ctl.checkPin('2580', now: t0.add(const Duration(seconds: 31))), isTrue);
      expect(c.read(settingsProvider).failedAttempts, 0);
      c.dispose();
    });

    test('desligar o PIN desliga a biometria', () async {
      final c = _container();
      final ctl = c.read(settingsProvider.notifier);
      await ctl.setBiometrics(true);
      expect(c.read(settingsProvider).biometrics, isFalse, reason: 'sem PIN não há biometria');
      await ctl.setPin('2580');
      await ctl.setBiometrics(true);
      await ctl.removePin();
      expect(c.read(settingsProvider).biometrics, isFalse);
      c.dispose();
    });
  });

  test('apagar todos os dados esvazia banco, arquivos e ajustes', () async {
    final env = await TestEnv.create();
    final p = await env.repo.createProject('P');
    final file = File(env.storage.absolute('projetos/${p.id}/arquivos/x.vcf'));
    await file.parent.create(recursive: true);
    await file.writeAsString('##fileformat=VCFv4.3\n');
    final ctl = env.container.read(settingsProvider.notifier);
    await ctl.setPin('2580');
    await env.storage.blobs.writeBytes('aprender/progresso.json', Uint8List.fromList('{}'.codeUnits));

    await wipeAll(db: env.db, storage: env.storage, core: env.core, settings: ctl);

    for (final table in env.db.allTables) {
      expect(await env.db.select(table).get(), isEmpty, reason: table.actualTableName);
    }
    expect(await Directory(env.storage.absolute('projetos')).exists(), isFalse);
    expect(await env.storage.blobs.exists(settingsFile), isFalse);
    expect(await env.storage.blobs.exists('aprender/progresso.json'), isFalse, reason: 'modo estudante também');
    expect(env.container.read(settingsProvider).lockEnabled, isFalse);
    await env.dispose();
  });

  group('bloqueio', () {
    testWidgets('sem PIN o app abre direto', (tester) async {
      final c = _container();
      await tester.pumpWidget(_gated(c));
      expect(find.text('conteúdo do app'), findsOneWidget);
      expect(find.text('Genoz bloqueado'), findsNothing);
    });

    testWidgets('com PIN abre bloqueado; PIN errado não entra, o certo entra', (tester) async {
      final c = _container(settings: AppSettings(pin: PinHash.create('2580', iterations: 100)));
      await tester.pumpWidget(_gated(c));
      await tester.pumpAndSettle();
      expect(find.text('Genoz bloqueado'), findsOneWidget);
      expect(find.text('conteúdo do app'), findsNothing);

      await _typePin(tester, '1111');
      expect(find.text('PIN incorreto'), findsOneWidget);
      expect(find.text('Genoz bloqueado'), findsOneWidget);

      await _typePin(tester, '2580');
      expect(find.text('Genoz bloqueado'), findsNothing);
      expect(find.text('conteúdo do app'), findsOneWidget);
    });

    testWidgets('biometria desbloqueia sozinha ao abrir', (tester) async {
      final bio = FakeBiometrics();
      final c = _container(settings: AppSettings(pin: PinHash.create('2580', iterations: 100), biometrics: true), bio: bio);
      await tester.pumpWidget(_gated(c));
      await tester.pumpAndSettle();
      expect(bio.calls, 1);
      expect(find.text('conteúdo do app'), findsOneWidget);
    });

    testWidgets('volta a bloquear só depois do tempo escolhido em segundo plano', (tester) async {
      final c = _container(settings: AppSettings(pin: PinHash.create('2580', iterations: 100)));
      var now = DateTime(2026, 10, 1, 12);
      c.read(lockProvider.notifier)
        ..clock = (() => now)
        ..unlock();
      await tester.pumpWidget(_gated(c));

      Future<void> background(Duration away) async {
        for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
          tester.binding.handleAppLifecycleStateChanged(s);
        }
        now = now.add(away);
        for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
          tester.binding.handleAppLifecycleStateChanged(s);
        }
        await tester.pumpAndSettle();
      }

      await background(const Duration(seconds: 20)); // ex.: escolher um arquivo no seletor do sistema
      expect(find.text('Genoz bloqueado'), findsNothing);
      await background(const Duration(minutes: 2));
      expect(find.text('Genoz bloqueado'), findsOneWidget);
    });

    testWidgets('esqueci o PIN: apagar tudo libera o app e remove o PIN', (tester) async {
      final db = GenozDatabase(NativeDatabase.memory());
      addTearDown(() => tester.runAsync(db.close));
      final c = ProviderContainer(overrides: [
        appStorageProvider.overrideWithValue(AppStorage(MemoryBlobStore())),
        initialSettingsProvider.overrideWithValue(AppSettings(pin: PinHash.create('2580', iterations: 100))),
        biometricsProvider.overrideWithValue(FakeBiometrics(isAvailable: false)),
        genozCoreProvider.overrideWithValue(FakeGenozCore()),
        databaseProvider.overrideWithValue(db),
      ]);
      await tester.pumpWidget(_gated(c));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esqueci o PIN'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Apagar tudo');
      expect(tester.widget<FilledButton>(button).onPressed, isNull, reason: 'só depois de digitar a palavra');
      await tester.enterText(find.byType(TextField), 'apagar');
      await tester.pump();
      await tester.tap(button);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('conteúdo do app'), findsOneWidget);
      expect(c.read(settingsProvider).lockEnabled, isFalse);
    });
  });

  testWidgets('telas de ajustes, bloqueio e apagar cabem em tela pequena com fonte 130%', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final screen in <Widget>[const SettingsScreen(), const WipeScreen()]) {
      final c = _container(settings: AppSettings(pin: PinHash.create('2580', iterations: 100), biometrics: true),
          bio: FakeBiometrics(succeed: false));
      c.read(lockProvider.notifier).unlock();
      await tester.pumpWidget(_gated(c, home: screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$screen');
    }
    // Tela de bloqueio.
    final c = _container(settings: AppSettings(pin: PinHash.create('2580', iterations: 100), biometrics: true),
        bio: FakeBiometrics(succeed: false));
    await tester.pumpWidget(_gated(c));
    await tester.pumpAndSettle();
    expect(find.text('Genoz bloqueado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
