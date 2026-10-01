import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'l10n/generated/app_localizations.dart';
import 'platform/network_audit.dart';
import 'persistence/app_storage.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();
  NetworkAudit.instance.start();
  try {
    await RustLib.init();
  } catch (e) {
    // No navegador o núcleo exige WebAssembly com threads (isolamento de origem).
    runApp(_Unsupported(error: '$e'));
    return;
  }
  final storage = await AppStorage.open();
  runApp(
    ProviderScope(
      overrides: [appStorageProvider.overrideWithValue(storage)],
      child: const GenozApp(),
    ),
  );
}

/// As fontes embutidas (OFL) aparecem na tela de licenças do app.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, file) in [('Poppins', 'OFL-Poppins.txt'), ('Inter', 'OFL-Inter.txt')]) {
      yield LicenseEntryWithLineBreaks([family], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
}

/// Mostrada quando o núcleo não pode iniciar (navegador sem os recursos necessários).
class _Unsupported extends StatelessWidget {
  const _Unsupported({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.browser_not_supported, size: 56),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context).webUnsupported, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                ]),
              ),
            ),
          ),
        ),
      );
}
