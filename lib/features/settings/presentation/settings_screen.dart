import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../../authentication/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('settings_change_password'.tr(), style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'settings_new_password_hint'.tr(),
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('settings_cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('settings_password_too_short'.tr())));
                return;
              }
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(passwordController.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('settings_password_success'.tr()), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('settings_password_error'.tr(args: [e.toString()])), backgroundColor: Colors.red));
                }
              }
            },
            child: Text('settings_update'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text('settings_title'.tr(), style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionTitle('settings_appearance'.tr()),
          const SizedBox(height: 16),
          _buildSettingsCard(
            child: RadioGroup<ThemeMode>(
              groupValue: currentTheme,
              onChanged: (v) => ref.read(themeProvider.notifier).setTheme(v!),
              child: Column(
                children: [
                  _buildRadioTile<ThemeMode>(
                    title: 'settings_theme_light'.tr(),
                    icon: Icons.light_mode_outlined,
                    value: ThemeMode.light,
                  ),
                  _buildRadioTile<ThemeMode>(
                    title: 'settings_theme_dark'.tr(),
                    icon: Icons.dark_mode_outlined,
                    value: ThemeMode.dark,
                  ),
                  _buildRadioTile<ThemeMode>(
                    title: 'settings_theme_system'.tr(),
                    icon: Icons.settings_brightness_outlined,
                    value: ThemeMode.system,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('settings_language'.tr()),
          const SizedBox(height: 16),
          _buildSettingsCard(
            child: RadioGroup<String>(
              groupValue: context.locale.languageCode,
              onChanged: (v) {
                context.setLocale(Locale(v!));
                ref.read(localeProvider.notifier).state = Locale(v);
              },
              child: Column(
                children: [
                  _buildRadioTile<String>(
                    title: 'Español',
                    iconWidget: const Text('🇪🇸', style: TextStyle(fontSize: 20)),
                    value: 'es',
                  ),
                  _buildRadioTile<String>(
                    title: 'English',
                    iconWidget: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                    value: 'en',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('settings_security'.tr()),
          const SizedBox(height: 16),
          _buildSettingsCard(
            child: ListTile(
              title: Text('settings_change_password'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              leading: Icon(Icons.password_outlined, color: theme.colorScheme.primary),
              subtitle: isGuest ? Text('settings_guest_unavailable'.tr()) : null,
              enabled: !isGuest,
              onTap: _changePassword,
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('auth_logout'.tr()),
          const SizedBox(height: 16),
          _buildSettingsCard(
            child: ListTile(
              title: Text('auth_logout'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('auth_logout'.tr()),
                    content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('settings_cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ref.read(authProvider.notifier).logout();
                        },
                        child: Text('auth_logout'.tr(), style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 18));
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    IconData? icon,
    Widget? iconWidget,
    required T value,
  }) {
    final theme = Theme.of(context);
    return RadioListTile<T>(
      value: value,
      activeColor: theme.colorScheme.primary,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      secondary:
          iconWidget ?? Icon(icon, size: 20, color: theme.colorScheme.primary),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}

