import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/locale_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _changePassword() async {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_change_password'.tr()),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'settings_new_password_hint'.tr(),
            prefixIcon: const Icon(Icons.lock),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'settings_cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('settings_password_too_short'.tr())),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.currentUser?.updatePassword(
                  passwordController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('settings_password_success'.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'settings_password_error'.tr(args: [e.toString()]),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
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
    final currentTheme = ref.watch(themeProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'settings_appearance'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          RadioGroup<ThemeMode>(
            groupValue: currentTheme,
            onChanged: (ThemeMode? value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setTheme(value);
              }
            },
            child: Column(
              children: [
                ListTile(
                  title: Text('settings_theme_light'.tr()),
                  leading: const Icon(Icons.light_mode),
                  trailing: const Radio<ThemeMode>(
                    value: ThemeMode.light,
                  ),
                ),
                ListTile(
                  title: Text('settings_theme_dark'.tr()),
                  leading: const Icon(Icons.dark_mode),
                  trailing: const Radio<ThemeMode>(
                    value: ThemeMode.dark,
                  ),
                ),
                ListTile(
                  title: Text('settings_theme_system'.tr()),
                  leading: const Icon(Icons.settings_system_daydream),
                  trailing: const Radio<ThemeMode>(
                    value: ThemeMode.system,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text(
            'settings_language'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          RadioGroup<String>(
            groupValue: context.locale.languageCode,
            onChanged: (String? value) {
              if (value != null) {
                context.setLocale(Locale(value));
                ref.read(localeProvider.notifier).state = Locale(value);
              }
            },
            child: Column(
              children: [
                ListTile(
                  title: const Text('Español'),
                  leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
                  trailing: const Radio<String>(
                    value: 'es',
                  ),
                ),
                ListTile(
                  title: const Text('English'),
                  leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                  trailing: const Radio<String>(
                    value: 'en',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text(
            'settings_security'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text('settings_change_password'.tr()),
            leading: const Icon(Icons.password),
            subtitle: isGuest ? Text('settings_guest_unavailable'.tr()) : null,
            enabled: !isGuest,
            onTap: _changePassword,
          ),
        ],
      ),
    );
  }
}
