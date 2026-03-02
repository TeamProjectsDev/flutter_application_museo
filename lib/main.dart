import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:firebase_core/firebase_core.dart';
import 'core/routes/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/providers/locale_provider.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();

  // Inicialización de Firebase detectando la plataforma
  await Firebase.initializeApp(options: _getFirebaseOptions());

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      child: const ProviderScope(child: MuseoApp()),
    ),
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
      title: 'app_title'.tr(),
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
