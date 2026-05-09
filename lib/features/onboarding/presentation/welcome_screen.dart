import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isEnglish = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isEnglish = context.locale.languageCode == 'en';
  }

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_selected_language', true);
    if (mounted) {
      context.go('/onboarding');
    }
  }

  void _toggleLanguage(bool isEn) {
    setState(() {
      _isEnglish = isEn;
    });
    context.setLocale(Locale(isEn ? 'en' : 'es'));
  }

  @override
  Widget build(BuildContext context) {
    // Guarda de traducción: Evitamos mostrar Keys crudas durante el arranque
    if (context.locale.languageCode.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image with Blur
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),

          // 2. Center Content
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              decoration: BoxDecoration(
                color: const Color(0xFF121212).withValues(alpha: 0.95), // Cuadro negro premium
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo limpio (Sin aura)
                  Image.asset(
                    'assets/images/museo_logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.museum_outlined, size: 60, color: Color(0xFFCBA35C)),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'onboarding_welcome_title'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily:
                          'Serif', // Use a serif font if available, or default
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFEBC154), // Gold color
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    'onboarding_welcome_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Language Selector
                  _buildLanguageSelector(),
                  const SizedBox(height: 40),

                  // Start Button
                  _buildStartButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLangOption('EN', true),
          _buildLangOption('ES', false),
        ],
      ),
    );
  }

  Widget _buildLangOption(String label, bool isEn) {
    final isSelected = _isEnglish == isEn;
    return GestureDetector(
      onTap: () => _toggleLanguage(isEn),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEBC154) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.white30,
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _completeWelcome,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEBC154),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'onboarding_start_journey'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
