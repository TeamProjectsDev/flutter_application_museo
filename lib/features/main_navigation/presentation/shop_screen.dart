import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/services/stripe_service.dart';
import '../providers/shop_provider.dart';
import '../providers/payment_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  final String? preselectedItemId;
  final String? preselectedItemName;
  final String? preselectedImageUrl;
  final String? preselectedStlUrl;

  const ShopScreen({
    super.key,
    this.preselectedItemId,
    this.preselectedItemName,
    this.preselectedImageUrl,
    this.preselectedStlUrl,
  });

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _notesController = TextEditingController();

  Future<void> _submitRequest() async {
    if (widget.preselectedItemId == null) return;

    final success = await ref
        .read(shopProvider.notifier)
        .createRequest(
          itemId: widget.preselectedItemId!,
          itemName: widget.preselectedItemName!,
          imageUrl: widget.preselectedImageUrl!,
          stlUrl: widget.preselectedStlUrl!,
          notes: _notesController.text,
        );

    if (success && mounted) {
      // Notificar por correo invisible usando EmailJS
      final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
      final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
      final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';
      final adminEmailsStr = dotenv.env['ADMIN_EMAIL'] ?? '';

      if (serviceId.isNotEmpty && serviceId != 'tu_service_id_aqui') {
        final adminEmails = adminEmailsStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        for (final email in adminEmails) {
          try {
            await http.post(
              Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'service_id': serviceId,
                'template_id': templateId,
                'user_id': userId,
                'template_params': {
                  'to_email': email,
                  'item_name': widget.preselectedItemName,
                  'user_notes': _notesController.text,
                },
              }),
            );
          } catch (e) {
            debugPrint('Error enviando email a $email: $e');
          }
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('shop_success'.tr())));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Forzar reconstrucción por idioma
    final state = ref.watch(shopProvider);
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(title: Text('shop_title'.tr())),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDigitalServices(
              context,
              ref,
              paymentState,
            ), // Pass ref and paymentState
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.preselectedItemId != null)
                    _buildOrderForm(state)
                  else
                    _buildEmptyState(),
                  const SizedBox(height: 32),
                  Text(
                    'shop_my_requests'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMyRequests(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.print_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(
            'shop_3d_print_service'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'shop_3d_print_desc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showDonationDialog(
    BuildContext context,
    WidgetRef ref,
    PaymentState paymentState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Added this line
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            // Modified padding
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.volunteer_activism,
                size: 48,
                color: Colors.orange,
              ), // Modified icon
              const SizedBox(height: 16),
              const Text(
                'Apoya al Museo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu contribución nos ayuda a conservar y digitalizar más piezas históricas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDonationTier(
                    context,
                    ref,
                    paymentState,
                    '1€',
                    'Bronce',
                    Colors.brown.shade400,
                    'donacion_bronce',
                  ), // Modified call
                  _buildDonationTier(
                    context,
                    ref,
                    paymentState,
                    '5€',
                    'Plata',
                    Colors.blueGrey.shade300,
                    'donacion_plata',
                  ), // Modified call
                  _buildDonationTier(
                    context,
                    ref,
                    paymentState,
                    '15€',
                    'Oro',
                    Colors.amber.shade600,
                    'donacion_oro',
                  ), // Modified call
                ],
              ),
              const SizedBox(height: 16),
              if (paymentState.isLoading)
                const CircularProgressIndicator(), // Added this line
            ],
          ),
        );
      },
    );
  }

  Widget _buildDonationTier(
    BuildContext context,
    WidgetRef ref,
    PaymentState paymentState,
    String amount,
    String tier,
    Color color,
    String productId,
  ) {
    // Modified signature
    return InkWell(
      onTap: () async {
        final isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;

        final isDesktopOrWeb =
            kIsWeb ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux;

        // Pasarela Stripe para Web y PC (RevenueCat no soporta Web/Desktop directamente)
        if (isDesktopOrWeb) {
          try {
            // Mostrar modal de carga
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 24),
                    Text('Conectando con Stripe...'),
                  ],
                ),
              ),
            );

            // Obtener precio numérico (Ej: "5€" -> 500 centavos)
            final numericAmount =
                int.tryParse(amount.replaceAll('€', '').trim()) ?? 1;
            final cents = numericAmount * 100;

            final stripeUrl = await StripeService().createCheckoutSession(
              productName: 'Donación Museo: Nivel $tier',
              amountInCents: cents,
              currency: 'eur',
              successUrl:
                  'https://museo-padre-suarez.web.app/#/home', // Redirige al inicio si hay éxito
              cancelUrl: 'https://museo-padre-suarez.web.app/#/shop',
            );

            if (context.mounted) {
              Navigator.pop(context); // Cerrar Modal Loading Stripe
              Navigator.pop(context); // Cerrar Modal original de Donaciones
            }

            if (stripeUrl != null && stripeUrl.isNotEmpty) {
              await FirebaseAnalytics.instance.logEvent(
                name: 'donation_stripe_started',
                parameters: {'tier': tier, 'amount': cents},
              );
              await launchUrlString(
                stripeUrl,
                mode: LaunchMode.externalApplication,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error obteniendo enlace de Stripe.'),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // Remove loading

              String errorMessage = 'Asegúrate de tener conexión a Internet.';
              if (e.toString().contains('401') ||
                  e.toString().contains('Invalid API Key')) {
                errorMessage =
                    'El servicio de pagos (Stripe) no está configurado correctamente en este entorno.';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al procesar la donación: $errorMessage'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          return;
        }

        // Simulador Local para Móviles
        if (isTester &&
            (!paymentState.isReady || paymentState.products.isEmpty)) {
          Navigator.pop(context);
          await FirebaseAnalytics.instance.logEvent(
            name: 'donation_mock_success',
            parameters: {'tier': tier},
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '¡Gracias por tu donación de $amount ($tier)! (Simulación) ❤️',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        // Pago Real RevenueCat
        if (paymentState.isReady && paymentState.products.isNotEmpty) {
          try {
            final productToBuy = paymentState.products.firstWhere(
              (p) => p.identifier == productId,
              orElse: () => paymentState.products.first,
            );

            // Al intentar comprar, RevenueCat levanta la pasarela nativa sola, no cerramos el modal aún.
            final success = await ref
                .read(paymentProvider.notifier)
                .purchaseSpecificProduct(productToBuy);

            if (success && context.mounted) {
              Navigator.pop(context);
              await FirebaseAnalytics.instance.logEvent(
                name: 'donation_revenuecat_success',
                parameters: {'tier': tier},
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '¡Gracias por tu donación de $amount! Tu apoyo es vital. ❤️',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error en el pago: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Las donaciones reales aún no están activadas en producción.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              amount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tier,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalServices(
    BuildContext context,
    WidgetRef ref,
    PaymentState paymentState,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Servicios Digitales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  context,
                  title: 'Entrada\nDigital',
                  icon: Icons.qr_code_scanner_rounded,
                  color: Colors.green.shade600,
                  onTap: () => context.push('/payment'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceCard(
                  context,
                  title: 'Apoyar al\nMuseo',
                  icon: Icons.volunteer_activism_rounded,
                  color: Colors.orange.shade600,
                  onTap: () => _showDonationDialog(context, ref, paymentState),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderForm(ShopState state) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.preselectedImageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.art_track, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'shop_request_print_label'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        widget.preselectedItemName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'shop_instructions_scale'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'shop_notes_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('shop_confirm_request'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'shop_select_item'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/collection'),
            child: Text('shop_go_to_collection'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequests(ShopState state) {
    if (state.myRequests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'shop_no_requests'.tr(),
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: state.myRequests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(state.myRequests[index]);
      },
    );
  }

  Widget _buildRequestCard(PrintRequest req) {
    Color statusColor;
    IconData statusIcon;

    switch (req.status) {
      case PrintStatus.pendiente:
        statusColor = Colors.orange;
        statusIcon = Icons.timer;
        break;
      case PrintStatus.en_cura:
        statusColor = Colors.blue;
        statusIcon = Icons.settings_suggest;
        break;
      case PrintStatus.imprimiendo:
        statusColor = Colors.purple;
        statusIcon = Icons.print;
        break;
      case PrintStatus.listo:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          req.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'shop_status'.tr(args: [req.status.name.replaceAll('_', ' ')]),
        ),
        trailing: Text(
          '${req.timestamp.day}/${req.timestamp.month}/${req.timestamp.year}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}
