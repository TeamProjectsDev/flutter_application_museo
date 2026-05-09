import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../main_navigation/presentation/widgets/rank_badge_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('nav_profile'.tr()),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [theme.colorScheme.surface, const Color(0xFF0D1B2A)]
              : [theme.colorScheme.surface, const Color(0xFFF5F5F5)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 👤 Header de Usuario
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person, size: 60, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                authState.userName ?? 'home_guest'.tr(),
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const RankBadgeWidget(),
              const SizedBox(height: 40),

              // 📱 Menú de Opciones
              _buildProfileOption(
                context,
                icon: Icons.confirmation_number_outlined,
                title: 'profile_my_tickets'.tr(),
                subtitle: 'tickets_tab_tickets'.tr(),
                onTap: () => context.push('/tickets'),
              ),
              const SizedBox(height: 16),
              _buildProfileOption(
                context,
                icon: Icons.print_outlined,
                title: 'profile_3d_orders'.tr(),
                subtitle: 'tickets_tab_3d'.tr(),
                onTap: () => context.push('/3d-orders'),
              ),
              const SizedBox(height: 16),
              _buildProfileOption(
                context,
                icon: Icons.settings_outlined,
                title: 'settings_title'.tr(),
                subtitle: 'profile_language'.tr(),
                onTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 40),

              // 🚪 Cerrar Sesión
              TextButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/welcome');
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: Text('profile_logout'.tr(), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}
