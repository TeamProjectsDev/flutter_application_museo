import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/routes/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/providers/locale_provider.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();

  // Leer el locale guardado por EasyLocalization en SharedPreferences
  // para inicializar localeProvider con el valor correcto desde el primer frame.
  // EasyLocalization guarda el código de idioma bajo la clave 'selectedLocale'.
  final prefs = await SharedPreferences.getInstance();
  final savedCode = prefs.getString('selectedLocale');
  final initialLocale = savedCode != null
      ? Locale(savedCode)
      : const Locale('en');

  // Inicialización de Firebase detectando la plataforma
  await Firebase.initializeApp(options: _getFirebaseOptions());

  // Crashlytics: capturar errores no manejados del framework Flutter
  if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Capturar errores asíncronos de la plataforma nativa
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runZonedGuarded(
    () => runApp(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        child: ProviderScope(
          overrides: [localeProvider.overrideWith((ref) => initialLocale)],
          child: const MuseoApp(),
        ),
      ),
    ),
    (error, stack) {
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    },
  );
}

FirebaseOptions _getFirebaseOptions() {
  if (kIsWeb) {
    return FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY_WEB'] ?? '',
      appId: dotenv.env['FIREBASE_APP_ID_WEB'] ?? '',
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
      projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
      authDomain: "${dotenv.env['FIREBASE_PROJECT_ID']}.firebaseapp.com",
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID_WEB'] ?? '',
    );
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID_WEB'] ?? '',
      );
    case TargetPlatform.windows:
      return FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_WEB'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID_WEB'] ?? '',
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
        projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
        authDomain: "${dotenv.env['FIREBASE_PROJECT_ID']}.firebaseapp.com",
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID_WEB'] ?? '',
      );
    default:
      throw UnsupportedError('Plataforma no soportada por el momento.');
  }
}

class MuseoApp extends ConsumerWidget {
  const MuseoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    // Watch localeProvider — when settings change the locale, MuseoApp
    // rebuilds and propagates the new Locale down through the entire tree.
    final locale = ref.watch(localeProvider);
    final routerAsyncValue = ref.watch(routerProvider);

    if (routerAsyncValue.isLoading ||
        routerAsyncValue.hasError ||
        routerAsyncValue.value == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      onGenerateTitle: (ctx) => 'app_title'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: locale,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Integración de GoRouter dinámico
      routerConfig: routerAsyncValue.value,
      builder: (context, child) {
        final isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;
        if (isTester && child != null) {
          return Banner(
            message: 'TESTER',
            location: BannerLocation.topEnd,
            color: Colors.orange,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
            child: child,
          );
        }
        return child ?? const SizedBox();
      },
    );
  }
}
