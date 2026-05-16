import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/admin/presentation/ticket_scanner_screen.dart';

import '../../features/main_navigation/presentation/main_scaffold.dart';
import '../../features/main_navigation/presentation/home_screen.dart';
import '../../features/main_navigation/presentation/bio_magazine_screen.dart';
import '../../features/main_navigation/presentation/map_screen.dart';
import '../../features/main_navigation/presentation/collection_screen.dart';
import '../../features/immersive_3d/presentation/viewer_3d_screen.dart';
import '../../features/vr_360/vr_360_screen.dart';
import '../../features/augmented_reality/ar_screen.dart';
import '../../features/authentication/auth_screen.dart';
import '../../features/authentication/providers/auth_provider.dart';
import '../../features/main_navigation/presentation/shop_screen.dart';
import '../../features/main_navigation/presentation/admin_orders_screen.dart';
import '../../features/main_navigation/presentation/payment_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/language_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/main_navigation/presentation/my_tickets_screen.dart';
import '../../features/main_navigation/presentation/my_3d_orders_screen.dart';
import '../../features/admin/presentation/admin_config_screen.dart';
import '../../features/admin/presentation/direct_sale_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final _shellNavigatorMagazineKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellMagazine',
);
final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellMap');
final _shellNavigatorCollectionKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellCollection',
);

// We need an asynchronous provider to determine the initial route

final routerProvider = FutureProvider<GoRouter>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final hasSelectedLanguage = prefs.getBool('has_selected_language') ?? false;
  final analytics = FirebaseAnalytics.instance;

  String initialRoute = '/welcome';
  if (hasSelectedLanguage && hasSeenOnboarding) {
    initialRoute = '/home';
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: ref.watch(authListenableProvider),
    initialLocation: (Uri.base.toString().contains('payment/success') ||
            Uri.base.path.contains('payment/success'))
        ? '/payment/success'
        : (Uri.base.toString().contains('payment/cancel') ||
                Uri.base.path.contains('payment/cancel'))
            ? '/payment/cancel'
            : initialRoute,
    observers: [FirebaseAnalyticsObserver(analytics: analytics)],
    // 🛡️ RED DE SEGURIDAD: Si la ruta no existe o hay un error, volvemos a casa
    errorBuilder: (context, state) {
      debugPrint(
          '🚨 [Router] Error detectado en ruta: ${state.error}. Redirigiendo a /home');
      // Teletransporte automático a Home de forma segura
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    },
    redirect: (context, state) {
      if (state.error != null) return '/home';
      final authState = ref.read(authProvider);
      final String loc = state.uri.path;

      // Pantallas públicas
      final bool isPublic = loc == '/language' ||
          loc == '/onboarding' ||
          loc == '/welcome' ||
          loc == '/auth' ||
          loc.startsWith('/payment');

      // 🛡️ Si ya está en una pantalla pública y no está logueado, lo dejamos ahí
      if (!authState.isAuthenticated && isPublic) {
        return null; 
      }

      // 🛡️ Si no está logueado y la ruta no es pública, al welcome
      if (!authState.isAuthenticated && !isPublic) {
        return '/welcome';
      }

      // 🛡️ Si ya está logueado e intenta ir a auth o welcome, a home
      if (authState.isAuthenticated && (loc == '/welcome' || loc == '/auth')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => initialRoute,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMagazineKey,
            routes: [
              GoRoute(
                path: '/magazine',
                builder: (context, state) => const BioMagazineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMapKey,
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCollectionKey,
            routes: [
              GoRoute(
                path: '/collection',
                builder: (context, state) {
                  final room = state.uri.queryParameters['room'];
                  return CollectionScreen(filterRoom: room);
                },
              ),
            ],
          ),
        ],
      ),
      // Rutas fuera del Bottom Navigation
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/language',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ArScreen(),
      ),
      GoRoute(
        path: '/vr_explore',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final panoramaFile = state.uri.queryParameters['file'];
          return Vr360Screen(panoramaFileName: panoramaFile);
        },
      ),
      GoRoute(
        path: '/3d',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final modelFile = state.uri.queryParameters['model'];
          final room = state.uri.queryParameters['room'];
          return Viewer3DScreen(modelFileName: modelFile, room: room);
        },
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/shop',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/scanner',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TicketScannerScreen(),
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.isAdmin) return '/home';
          return null;
        },
      ),
      GoRoute(
        path: '/payment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final total = state.uri.queryParameters['total'] ?? '0';
          final subtotal = state.uri.queryParameters['subtotal'] ?? '0';
          final fees = state.uri.queryParameters['fees'] ?? '0';
          final tickets = state.uri.queryParameters['tickets'] ?? '{}';
          final printPieceName = state.uri.queryParameters['printPieceName'];
          return PaymentScreen(
            total: total,
            subtotal: subtotal,
            fees: fees,
            ticketsJson: tickets,
            printPieceName: printPieceName,
          );
        },
      ),
      GoRoute(
        path: '/payment/:status',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final status = state.pathParameters['status'] ?? '';
          return PaymentScreen(
            total: '0',
            subtotal: '0',
            fees: '0',
            ticketsJson: '{}',
            stripeSuccess: status == 'success',
            printPieceName: state.uri.queryParameters['printPieceName'],
          );
        },
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            const ProfileScreen(), // We will create this next
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin/config',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminConfigScreen(),
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.isAdmin) {
            return '/home';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/admin/sale',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DirectSaleScreen(),
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (!authState.isAdmin) return '/home';
          return null;
        },
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/tickets',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/3d-orders',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const My3DOrdersScreen(),
      ),
      GoRoute(
        path: '/my-tickets',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MyTicketsScreen(),
      ),
      // Deep link: museo://pieza/[itemId] abre el visor 3D directamente
      GoRoute(
        path: '/piece/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final modelFile = state.pathParameters['id'] ?? '';
          return Viewer3DScreen(modelFileName: modelFile);
        },
      ),
    ],
  );
});
