import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:yacht/generated/l10n/app_localizations.dart';
import 'package:yacht/l10n/locale_notifier.dart';
import 'package:yacht/ui/level_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const YachtApp());
}

/// Корневой виджет приложения (для integration_test и тестов).
class YachtApp extends StatelessWidget {
  const YachtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LocaleNotifier>(
      create: (_) => LocaleNotifier(),
      child: const _YachtMaterialApp(),
    );
  }
}

class _YachtMaterialApp extends StatelessWidget {
  const _YachtMaterialApp();

  @override
  Widget build(BuildContext context) {
    final localeNotifier = context.watch<LocaleNotifier>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yacht Paper Simulator',
      theme: ThemeData(
        fontFamily: 'monospace',
        primarySwatch: Colors.brown,
      ),
      locale: localeNotifier.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LevelSelectionScreen(),
    );
  }
}
