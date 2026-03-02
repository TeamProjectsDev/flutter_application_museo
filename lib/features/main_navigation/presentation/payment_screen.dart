import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/services/stripe_service.dart';
import '../providers/payment_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('payment_title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade900, Colors.deepPurple.shade500],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'payment_official_title'.tr(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'payment_desc'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (paymentState.error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        paymentState.error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'payment_name'.tr(),
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: Colors.white70,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white30,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'payment_name_required'.tr()
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'payment_email'.tr(),
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.white70,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white30,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'payment_email_required'.tr();
                            }
                            if (!value.contains('@')) {
                              return 'payment_email_invalid'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Selector de Fecha
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.deepPurple.shade900,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.deepPurple,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedDate == null
                                    ? Colors.white30
                                    : Colors.white,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDate == null
                                        ? 'payment_date_hint'.tr()
                                        : 'payment_date_selected'.tr(
                                            args: [
                                              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                            ],
                                          ),
                                    style: TextStyle(
                                      color: _selectedDate == null
                                          ? Colors.white70
                                          : Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedDate == null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                'payment_date_required'.tr(),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Botón de Compra
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: paymentState.isLoading
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate() ||
                                  _selectedDate == null) {
                                if (_selectedDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'payment_date_missing'.tr(),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                                return;
                              }

                              final isTester =
                                  int.tryParse(dotenv.env['TESTER'] ?? '0') ==
                                  1;

                              final isDesktopOrWeb =
                                  kIsWeb ||
                                  defaultTargetPlatform ==
                                      TargetPlatform.windows ||
                                  defaultTargetPlatform ==
                                      TargetPlatform.macOS ||
                                  defaultTargetPlatform == TargetPlatform.linux;

                              // MODO PAGOS WEB / PC (Stripe)
                              if (isDesktopOrWeb) {
                                try {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => AlertDialog(
                                      content: Row(
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(width: 24),
                                          Text('payment_connecting'.tr()),
                                        ],
                                      ),
                                    ),
                                  );

                                  final stripeUrl = await StripeService()
                                      .createCheckoutSession(
                                        productName: 'Entrada Digital Museo',
                                        amountInCents: 200, // 2.00 €
                                        currency: 'eur',
                                        successUrl:
                                            'https://museo-padre-suarez.web.app/#/home',
                                        cancelUrl:
                                            'https://museo-padre-suarez.web.app/#/payment',
                                      );

                                  if (context.mounted)
                                    Navigator.pop(context); // Cierra Loading

                                  if (stripeUrl != null &&
                                      stripeUrl.isNotEmpty) {
                                    await FirebaseAnalytics.instance.logEvent(
                                      name: 'ticket_stripe_started',
                                      parameters: {'type': 'digital_entry'},
                                    );
                                    await launchUrlString(
                                      stripeUrl,
                                      mode: LaunchMode.externalApplication,
                                    );
                                    // Asumimos éxito al redirigir para soltar el ticket (Demo version behavior)
                                    if (context.mounted) {
                                      _sendTicketEmail(
                                        _emailController.text.trim(),
                                        _nameController.text.trim(),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'payment_redirect'.tr(),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      context.pop();
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    if (Navigator.canPop(context))
                                      Navigator.pop(context); // Cierra Loading

                                    String errorMessage =
                                        'Asegúrate de tener conexión a Internet.';
                                    if (e.toString().contains('401') ||
                                        e.toString().contains(
                                          'Invalid API Key',
                                        )) {
                                      errorMessage =
                                          'El servicio de pagos (Stripe) no está configurado correctamente en este entorno.';
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al procesar el pago: $errorMessage',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                                return;
                              }

                              // MODO SIMULACIÓN MÓVIL (Si no hay llaves de RevenueCat o productos, o Modo Tester)
                              if (!paymentState.isReady ||
                                  paymentState.products.isEmpty ||
                                  isTester) {
                                await FirebaseAnalytics.instance.logEvent(
                                  name: 'ticket_mock_success',
                                  parameters: {'type': 'digital_entry'},
                                );
                                if (context.mounted) {
                                  _showMockPaymentDialog(
                                    context,
                                    _emailController.text.trim(),
                                    _nameController.text.trim(),
                                  );
                                }
                                return;
                              }

                              // MODO REAL (RevenueCat)
                              final success = await ref
                                  .read(paymentProvider.notifier)
                                  .purchaseTicket();

                              if (success && context.mounted) {
                                await FirebaseAnalytics.instance.logEvent(
                                  name: 'ticket_revenuecat_success',
                                  parameters: {'type': 'digital_entry'},
                                );
                                _sendTicketEmail(
                                  _emailController.text.trim(),
                                  _nameController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '¡Pago completado! Boleto enviado a tu correo.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                context.pop();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child: paymentState.isLoading
                          ? const CircularProgressIndicator()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.payment),
                                const SizedBox(width: 8),
                                Text(
                                  paymentState.products.isNotEmpty
                                      ? 'payment_buy'.tr(
                                          args: [
                                            paymentState
                                                .products
                                                .first
                                                .priceString,
                                          ],
                                        )
                                      : 'payment_buy'.tr(args: ['2.00 €']),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'payment_secure'.tr(),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sendTicketEmail(String targetEmail, String targetName) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TICKET_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isNotEmpty &&
        templateId.isNotEmpty &&
        targetEmail.isNotEmpty &&
        _selectedDate != null) {
      final dateStr =
          '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';

      // Creamos un ID que contenga la fecha para validación rápida visual
      final ticketId =
          'TK-${_selectedDate!.year}${_selectedDate!.month.toString().padLeft(2, '0')}${_selectedDate!.day.toString().padLeft(2, '0')}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Creamos un texto legible y bonito para que cualquier móvil lo lea al escanear
      final qrText =
          '''🎟️ ENTRADA DE MUSEO
Localizador: $ticketId
Visitante: $targetName
Fecha de Visita: $dateStr''';

      // Lo codificamos en formato URL para enviarlo a QuickChart sin problemas de espacios
      final qrUrlEncoded = Uri.encodeComponent(qrText);
      final qrUrl = 'https://quickchart.io/qr?text=$qrUrlEncoded&size=400';

      // Guardar el ticket en la base de datos de Firebase (Firestore) para el panel Admin
      try {
        await FirebaseFirestore.instance.collection('tickets').add({
          'ticketId': ticketId,
          'visitorName': targetName,
          'visitorEmail': targetEmail,
          'visitDate': dateStr,
          'purchaseDate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error guardando ticket en Firestore: $e');
      }

      // Preparar lista de correos que recibirán el ticket (El comprador + Administradores)
      final adminEmailsStr = dotenv.env['ADMIN_EMAIL'] ?? '';
      final List<String> recipients = [targetEmail];

      if (adminEmailsStr.isNotEmpty) {
        final adminEmails = adminEmailsStr
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty);
        recipients.addAll(adminEmails);
      }

      // Enviar el correo a cada uno de los destinatarios
      for (final emailToSend in recipients) {
        try {
          await http.post(
            Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'service_id': serviceId,
              'template_id': templateId,
              'user_id': userId,
              'template_params': {
                'to_email': emailToSend,
                'name': targetName,
                'ticket_id': ticketId,
                'qr_image_url': qrUrl,
                'visit_date': dateStr,
                'purchase_date': DateTime.now().toString().split(' ')[0],
              },
            }),
          );
        } catch (e) {
          debugPrint('Error enviando ticket a $emailToSend: $e');
        }
      }
    }
  }

  void _showMockPaymentDialog(BuildContext context, String email, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('payment_mock_title'.tr()),
        content: Text('payment_mock_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('payment_mock_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendTicketEmail(email, name);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('payment_mock_success'.tr()),
                  backgroundColor: Colors.orange,
                ),
              );
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: Text('payment_mock_confirm'.tr()),
          ),
        ],
      ),
    );
  }
}
