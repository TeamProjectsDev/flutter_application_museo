import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/locale_provider.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  Future<void> _selectLanguage(
    BuildContext context,
    WidgetRef ref,
    String langCode,
  ) async {
    // 1. Cambiar el idioma en EasyLocalization (persiste en SharedPreferences)
    await context.setLocale(Locale(langCode));

    // 2. Actualizar localeProvider para que MaterialApp rebuilde al instante
    ref.read(localeProvider.notifier).state = Locale(langCode);

    // 3. Guardar preferencia para saltarse esta pantalla la próxima vez
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_selected_language', true);

    // 4. Decidir a dónde ir
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (!context.mounted) return;

    if (hasSeenOnboarding) {
      context.go('/auth');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Icono / Logo
              Icon(
                Icons.language,
                size: 100,
                color: isDark ? Colors.amber.shade400 : Colors.deepPurple,
              ),
              const SizedBox(height: 32),

              // Título
              Text(
                'Elige tu idioma\nChoose your language',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              // Botón Inglés
              _LanguageButton(
                title: 'English',
                subtitle: 'Inglés',
                onTap: () => _selectLanguage(context, ref, 'en'),
                color: isDark ? Colors.amber.shade700 : Colors.deepPurple,
              ),
              const SizedBox(height: 16),

              // Botón Español
              _LanguageButton(
                title: 'Español',
                subtitle: 'Spanish',
                onTap: () => _selectLanguage(context, ref, 'es'),
                color: isDark ? Colors.amber.shade700 : Colors.deepPurple,
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _LanguageButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }
}
