import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'providers/auth_provider.dart';
import '../main_navigation/presentation/widgets/rank_badge_widget.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena todos los campos.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        await ref.read(authProvider.notifier).login(email, password);
      } else {
        await ref.read(authProvider.notifier).register(email, password);
      }
    } catch (e) {
      // Error handling via provider state
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // 🖼️ Fondo Inmersivo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1554907984-15263bfd63bd?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 🌑 Overlay Oscuro
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          // 📝 Contenido
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withValues(alpha: 0.9), // Fondo negro profundo premium
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: authState.isAuthenticated
                      ? _buildSuccessView(context, authState.userName)
                      : _buildFormView(context, authState.error),
                ),
              ),
            ),
          ),
          // ⬅️ Botón Atrás
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
              onPressed: () => context.go('/home'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, String? name) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFFCBA35C)),
        const SizedBox(height: 24),
        Text(
          name == 'Invitado' ? 'auth_hello_guest'.tr() : 'auth_hi'.tr(args: [name ?? '']),
          style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const RankBadgeWidget(),
        const SizedBox(height: 48),
        _buildButton(
          context,
          text: 'auth_go_museum'.tr(),
          onPressed: () => context.go('/home'),
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          child: Text('auth_logout'.tr(), style: const TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  Widget _buildFormView(BuildContext context, String? error) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🏛️ Logo Oficial del Museo (Limpio)
        SizedBox(
          width: 180,
          height: 180,
          child: Center(
            child: Image.asset(
              'assets/images/museo_logo.png',
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.museum_outlined, size: 80, color: Color(0xFFCBA35C)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isLoginMode ? 'auth_access'.tr() : 'Únete al Museo',
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEBC154),
          ),
        ),
        const SizedBox(height: 16),
        if (error != null) ...[
          _buildErrorLabel(error),
          const SizedBox(height: 12),
        ],
        _buildTextField(
          controller: _emailController,
          label: 'auth_email'.tr(),
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _passwordController,
          label: 'auth_pass'.tr(),
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFFCBA35C),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        if (_isLoginMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              child: Text(
                'auth_forgot'.tr(), 
                style: const TextStyle(color: Color(0xFFEBC154), fontSize: 11),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (_isLoading)
          const CircularProgressIndicator(color: Color(0xFFCBA35C))
        else
          Column(
            children: [
              _buildButton(
                context,
                text: _isLoginMode ? 'auth_login'.tr() : 'Registrarse',
                onPressed: _submit,
                isPrimary: true,
              ),
              const SizedBox(height: 10),
              _buildButton(
                context,
                text: 'Continuar con Google',
                onPressed: () => ref.read(authProvider.notifier).loginWithGoogle(),
                isPrimary: false,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 40, // 3 veces más grande que el estándar de 14-16px
                  cacheHeight: 120,
                ),
              ),
              const SizedBox(height: 10),
              _buildButton(
                context,
                text: 'Entrar como Invitado',
                onPressed: () => ref.read(authProvider.notifier).loginAsGuest(),
                isPrimary: false,
                icon: const Icon(Icons.person_outline, size: 32, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 16),
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode ? 'auth_no_account'.tr() : 'auth_has_account'.tr(),
                  style: const TextStyle(color: Color(0xFFCBA35C), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 14), // Texto oscuro premium
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFFCBA35C)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9F6F0), // Blanco Marfil
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFCBA35C).withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBA35C), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required String text,
      required VoidCallback onPressed,
      required bool isPrimary,
      Widget? icon}) {
    return SizedBox(
      width: double.infinity,
      height: 50, // Un pelín más compacto
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isPrimary ? const Color(0xFFCBA35C) : Colors.transparent,
          foregroundColor: isPrimary ? Colors.black : Colors.white, // Letras blancas para secundarios
          elevation: isPrimary ? 2 : 0,
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFCBA35C), width: 1.5), // Borde Dorado
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon,
              const SizedBox(width: 8), // Reducido de 12 a 8
            ],
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Reducido de 16 a 14
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorLabel(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
      child: Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
    );
  }

  Future<void> _resetPassword() async {
    final emailController = TextEditingController(text: _emailController.text);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('auth_reset_title'.tr(), style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('auth_reset_desc'.tr(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('settings_cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.trim().isEmpty) return;
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('auth_reset_sent'.tr()), backgroundColor: Colors.green));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
              }
            },
            child: Text('auth_send_link'.tr()),
          ),
        ],
      ),
    );
  }
}
