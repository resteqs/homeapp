import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeapp/globals/app_state.dart';
import 'package:homeapp/globals/themes.dart';
import 'package:homeapp/globals/router.dart';
import 'package:homeapp/l10n/app_localizations.dart';

@NowaGenerated()
late final SharedPreferences sharedPrefs;

@NowaGenerated()
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  sharedPrefs = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

@NowaGenerated({'visibleInNowa': false})

/// Root widget that wires global state providers and app-wide router/i18n.
class MyApp extends StatelessWidget {
  @NowaGenerated()
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (context) => AppState()),
      ],
      builder: (context, child) => MaterialApp.router(
        theme: AppState.of(context).theme,
        darkTheme: lightTheme,
        themeMode: ThemeMode.light,
        locale: AppState.of(context).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
      ),
    );
  }
}
