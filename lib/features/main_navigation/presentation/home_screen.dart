import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../authentication/providers/auth_provider.dart';
import 'widgets/rank_badge_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 🏛️ Perfil de Usuario y Rango (Cabecera Real)
          SliverToBoxAdapter(
            child: _buildUserHeader(context, authState),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 🏺 PIEZAS DESTACADAS (Reales)
                _buildSectionHeader(context, 'home_curated_title'.tr(), 'home_curated_desc'.tr()),
                const SizedBox(height: 20),
                _buildFeaturedArtifacts(context),

                const SizedBox(height: 40),

                // 🎫 SECCIÓN DE TIENDA Y ENTRADAS
                _buildSectionHeader(context, 'nav_tickets'.tr(), 'shop_plan_desc'.tr()),
                const SizedBox(height: 20),
                _buildShopCard(context),
                
                const SizedBox(height: 40),

                // 📂 EXPLORACIÓN POR CATEGORÍA
                _buildSectionHeader(context, 'home_departments'.tr(), 'home_departments_desc'.tr()),
                const SizedBox(height: 20),
                _buildRealFeaturesGrid(context),
                
                const SizedBox(height: 40),
                
                // Admin Access (Solo si es admin)
                if (authState.isAdmin) ...[
                   _buildSectionHeader(context, 'admin_v2_title'.tr(), 'admin_v2_desc'.tr()),
                   const SizedBox(height: 16),
                   _buildAdminCard(context),
                   const SizedBox(height: 40),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, AuthState authState) {
    final theme = Theme.of(context);
    final userName = authState.userName ?? 'Padre Suárez';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person_outline, color: theme.colorScheme.primary, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home_welcome'.tr(args: [userName]),
                        style: theme.textTheme.displayMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
                      ),
                      Text(
                        'home_start_exploring'.tr(),
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              // Botón de Ajustes Grande y Dorado
              IconButton(
                icon: Icon(Icons.settings_outlined, color: theme.colorScheme.primary, size: 36),
                onPressed: () => context.push('/settings'),
                tooltip: 'settings_title'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const RankBadgeWidget(), 
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: theme.textTheme.displayMedium?.copyWith(fontSize: 16, letterSpacing: 1.5, color: theme.colorScheme.primary)),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      ],
    );
  }

  Widget _buildFeaturedArtifacts(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/featured_mandible.png'), // Usamos la imagen generada (asumiendo que se copió)
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/3d?model=mandibula_hombre.glb'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(4)),
                child: const Text('COLECCIÓN DE ANATOMÍA', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              const Text('Mandíbula Humana', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Estudio osteológico real del museo', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push('/shop'),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: -10,
              child: Icon(Icons.shopping_bag_outlined, size: 100, color: theme.colorScheme.primary.withValues(alpha: 0.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('home_tag_shop'.tr(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text('shop_plan_visit'.tr(), style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold, height: 1.2)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.2), size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealFeaturesGrid(BuildContext context) {
    return Column(
      children: [
        _buildFeatureCard(
          context,
          tag: 'home_tag_collection'.tr(),
          title: 'home_3d_gallery'.tr(),
          subtitle: 'home_3d_gallery_desc'.tr(),
          icon: Icons.view_in_ar,
          onTap: () => context.push('/collection'),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context,
          tag: 'home_tag_immersion'.tr(),
          title: 'home_360_environments'.tr(),
          subtitle: 'home_360_environments_desc'.tr(),
          icon: Icons.panorama_horizontal_select,
          onTap: () => context.push('/collection?tab=1'),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context,
          tag: 'home_tag_tools'.tr(),
          title: 'home_scan_ar'.tr(),
          subtitle: 'home_scan_ar_desc'.tr(),
          icon: Icons.qr_code_scanner,
          onTap: () => context.push('/scan'),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context,
          tag: 'home_tag_news'.tr(),
          title: 'home_digital_magazine'.tr(),
          subtitle: 'home_digital_magazine_desc'.tr(),
          icon: Icons.article_outlined,
          onTap: () => context.push('/magazine'),
        ),
        const SizedBox(height: 16),
        _buildFeatureCard(
          context,
          tag: 'home_tag_location'.tr(),
          title: 'home_museum_map'.tr(),
          subtitle: 'home_museum_map_desc'.tr(),
          icon: Icons.map_outlined,
          onTap: () => context.push('/map'),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required String tag, required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 10,
              bottom: -10,
              child: Icon(icon, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tag, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface.withValues(alpha: 0.2), size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/admin/orders'),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('admin_v2_panel_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('admin_v2_panel_desc'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}
