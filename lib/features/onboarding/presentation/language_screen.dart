import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/locale_provider.dart';
import 'dart:ui';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  Future<void> _selectLanguage(
    BuildContext context,
    WidgetRef ref,
    String langCode,
  ) async {
    await context.setLocale(Locale(langCode));
    ref.read(localeProvider.notifier).state = Locale(langCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_selected_language', true);
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
    final goldColor = const Color(0xFFEBC154);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1554907984-15263bfd63bd?q=80&w=1000&auto=format&fit=crop',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.7),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(color: goldColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.translate_rounded, size: 60, color: goldColor),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'IDIOMA / LANGUAGE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: goldColor,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selecciona tu lengua de exploración\nSelect your exploration language',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60),

                  _LanguageOption(
                    title: 'ESPAÑOL',
                    subtitle: 'SPANISH',
                    onTap: () => _selectLanguage(context, ref, 'es'),
                    goldColor: goldColor,
                  ),
                  const SizedBox(height: 20),
                  _LanguageOption(
                    title: 'ENGLISH',
                    subtitle: 'INGLÉS',
                    onTap: () => _selectLanguage(context, ref, 'en'),
                    goldColor: goldColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color goldColor;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.goldColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: goldColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: goldColor.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: goldColor, size: 16),
          ],
        ),
      ),
    );
  }
}
