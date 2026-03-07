import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../authentication/providers/auth_provider.dart';
import 'widgets/rank_badge_widget.dart';
import '../../../core/providers/locale_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // Suscribirse al localeProvider para que Riverpod invalide este widget
    // cuando cambie el idioma y los tr() se reevalúen con el locale correcto.
    ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'profile_settings'.tr(),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'home_welcome'.tr(args: [authState.userName ?? 'home_guest'.tr()]),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'onboarding_title_1'.tr(),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Center(child: RankBadgeWidget()),
          const SizedBox(height: 32),
          _buildMenuCard(
            context,
            title: 'home_3d_viewer'.tr(),
            icon: Icons.view_in_ar,
            route: '/3d',
            color: Colors.blueAccent,
          ),
          _buildMenuCard(
            context,
            title: 'home_vr_explore'.tr(),
            icon: Icons.threed_rotation,
            route: '/vr_explore',
            color: Colors.purpleAccent,
          ),
          _buildMenuCard(
            context,
            title: 'home_ar'.tr(),
            icon: Icons.camera_alt,
            route: '/scan',
            color: Colors.greenAccent,
          ),
          _buildMenuCard(
            context,
            title: 'home_shop'.tr(),
            icon: Icons.shopping_bag_outlined,
            route: '/shop',
            color: Colors.pinkAccent,
          ),

          // Solo visible para administradores
          if (authState.isAdmin)
            _buildMenuCard(
              context,
              title: 'home_admin_orders'.tr(),
              icon: Icons.admin_panel_settings_outlined,
              route: '/admin/orders',
              color: Colors.blueGrey,
            ),

          _buildMenuCard(
            context,
            title: 'home_profile'.tr(),
            icon: Icons.person,
            route: '/auth',
            color: Colors.orangeAccent,
          ),
          _buildMenuCard(
            context,
            title: 'Mis Entradas',
            icon: Icons.confirmation_number_outlined,
            route: '/my-tickets',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String route,
    required Color color,
  }) {
    return Semantics(
      label: title,
      button: true,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: ExcludeSemantics(
            child: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: ExcludeSemantics(
            child: const Icon(Icons.arrow_forward_ios),
          ),
          onTap: () => context.push(route),
        ),
      ),
    );
  }
}
