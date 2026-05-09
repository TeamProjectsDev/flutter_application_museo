import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../core/services/stripe_service.dart';
import '../providers/payment_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../../core/providers/config_provider.dart';
import '../../../core/models/museum_config.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String total;
  final String subtotal;
  final String fees;
  final String ticketsJson;

  const PaymentScreen({
    super.key,
    this.total = "0",
    this.subtotal = "0",
    this.fees = "0",
    this.ticketsJson = "{}",
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));

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
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentState = ref.watch(paymentProvider);
    final tickets = json.decode(widget.ticketsJson);
    final isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('checkout_title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('checkout_title'.tr(),
                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 32)),
              const SizedBox(height: 8),
              Text('checkout_desc'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6))),
              const SizedBox(height: 40),

              // 💳 Payment Details Form
              _buildPaymentForm(theme),

              const SizedBox(height: 40),

              // 📊 Checkout Order Summary
              _buildCheckoutSummary(theme, tickets),

              const SizedBox(height: 40),

              // 🔒 Confirm Button or Warning
              Builder(
                builder: (context) {
                  final configState = ref.watch(configProvider);
                  final config = configState.config;
                  final currentUser = FirebaseAuth.instance.currentUser;
                  
                  if (configState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 🚩 Comprobación 0: Usuario Autenticado
                  if (currentUser == null) {
                    return Column(
                      children: [
                        _buildWarningBox(theme, 'auth_required_checkout'.tr(), Icons.account_circle),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.push('/auth'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('auth_login'.tr().toUpperCase()),
                          ),
                        ),
                      ],
                    );
                  }

                  // 🚩 Comprobación 1: Cierre Global
                  if (config != null && !config.isGlobalOpen) {
                    return _buildWarningBox(theme, 'museum_closed_global'.tr(), Icons.lock);
                  }

                  // 🚩 Comprobación 2: Estado del día seleccionado
                  if (_selectedDate != null && config != null) {
                    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                    final override = config.calendarOverrides[dateKey];
                    
                    if (override != null) {
                      if (override.status == DayStatus.closed) {
                        return _buildWarningBox(theme, override.reason ?? 'museum_closed_day'.tr(), Icons.event_busy);
                      }
                      if (override.status == DayStatus.fullyBooked) {
                        return _buildWarningBox(theme, 'museum_full_day'.tr(), Icons.people_outline);
                      }
                      if (override.status == DayStatus.event) {
                        return _buildWarningBox(theme, override.reason ?? 'museum_event_day'.tr(), Icons.stars);
                      }
                    }
                  }

                  // 🚩 Comprobación 3: Aforo Máximo (Comparar pedido actual con límite admin)
                  final Map<String, dynamic> ticketsMap = json.decode(widget.ticketsJson);
                  final int totalRequested = (ticketsMap['general'] ?? 0) + (ticketsMap['student'] ?? 0);
                  
                  if (config != null && totalRequested > config.maxDailyCapacity) {
                    return _buildWarningBox(
                      theme, 
                      'museum_capacity_exceeded'.tr(args: [config.maxDailyCapacity.toString()]), 
                      Icons.groups_outlined
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (paymentState.isLoading ||
                              _nameController.text.trim().isEmpty ||
                              !_emailController.text.contains('@') ||
                              (_selectedDate == null && !isTester))
                          ? null
                          : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: paymentState.isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('checkout_confirm'.tr(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle, size: 18),
                              ],
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('checkout_secure'.tr(),
                    style:
                        const TextStyle(color: Colors.white30, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('checkout_details'.tr(),
                    style:
                        theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
                Icon(Icons.lock_outline,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 18),
              ],
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('checkout_cardholder'.tr()),
            _buildSimpleField(controller: _nameController, hint: 'JOHN DOE'),
            const SizedBox(height: 20),
            _buildFieldLabel('checkout_card_num'.tr()),
            _buildSimpleField(
                controller: _cardController,
                hint: '0000 0000 0000 0000',
                icon: Icons.credit_card),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('checkout_expiry'.tr()),
                      _buildSimpleField(
                          controller: _expiryController, hint: 'MM/YY'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('checkout_cvc'.tr()),
                      _buildSimpleField(
                          controller: _cvcController, hint: '123'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFieldLabel('checkout_email'.tr()),
            _buildSimpleField(
                controller: _emailController, hint: 'john.doe@example.com'),
            const SizedBox(height: 20),
            _buildFieldLabel('VISIT DATE'),
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'SELECT DATE'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: TextStyle(
                          color: _selectedDate == null
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.2)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          fontSize: 14),
                    ),
                    Icon(Icons.calendar_today,
                        size: 16,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label,
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1)),
    );
  }

  Widget _buildSimpleField(
      {required TextEditingController controller,
      required String hint,
      IconData? icon}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        prefixIcon: icon != null
            ? Icon(icon,
                size: 18,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3))
            : null,
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCheckoutSummary(ThemeData theme, Map<String, dynamic> tickets) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('shop_order_summary'.tr(),
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
          const SizedBox(height: 20),
          if (tickets['general'] > 0)
            _summaryRow(
                '${'shop_item_general_title'.tr()} x${tickets['general']}',
                (tickets['general'] * 25.0).toStringAsFixed(2)),
          if (tickets['student'] > 0)
            _summaryRow(
                '${'shop_item_student_title'.tr()} x${tickets['student']}',
                (tickets['student'] * 15.0).toStringAsFixed(2)),
          if (tickets['audio'] > 0)
            _summaryRow('${'shop_item_audio_title'.tr()} x${tickets['audio']}',
                (tickets['audio'] * 8.0).toStringAsFixed(2)),
          if (tickets['print'] > 0)
            _summaryRow('3D Print (${tickets['print']}mm)',
                (10.0 + tickets['print'] * 0.2).toStringAsFixed(2)),
          const Divider(color: Colors.white10, height: 32),
          _summaryRow('shop_subtotal'.tr(), widget.subtotal, isSmall: true),
          _summaryRow('shop_fee'.tr(), widget.fees, isSmall: true),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('shop_total'.tr(), style: const TextStyle(fontSize: 18)),
              Text('\$${double.parse(widget.total).toStringAsFixed(2)}',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: isSmall ? 0.3 : 0.7),
                  fontSize: isSmall ? 11 : 13)),
          Text('\$$value',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isSmall ? 11 : 13)),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    final isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;

    if (isTester) {
      _showMockPaymentDialog();
      return;
    }

    try {
      ref.read(paymentProvider.notifier).setLoading(true);

      final stripeUrl = await StripeService().createCheckoutSession(
        productName: 'Reserva Museo Padre Suárez',
        amountInCents: (double.parse(widget.total) * 100).toInt(),
        currency: 'eur',
        successUrl: 'https://museo-padre-suarez.web.app/#/home',
        cancelUrl: 'https://museo-padre-suarez.web.app/#/shop',
      );

      ref.read(paymentProvider.notifier).setLoading(false);

      if (stripeUrl != null && stripeUrl.isNotEmpty) {
        await launchUrlString(stripeUrl, mode: LaunchMode.externalApplication);
        if (mounted) context.pop();
      }
    } catch (e) {
      ref.read(paymentProvider.notifier).setLoading(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showMockPaymentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Simulación de Pago',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'En el modo TESTER, simulamos la pasarela de Stripe. El pago se marcará como completado y se generarán tus entradas en Firestore y EmailJS.',
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processOrder();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('¡Pedido completado con éxito! Revisa tu correo.'),
                  backgroundColor: Colors.green));
              context.pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                foregroundColor: Colors.green),
            child: const Text('Simular Pago'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Theme.of(context).colorScheme.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _processOrder() async {
    final targetEmail = _emailController.text.trim();
    final targetName = _nameController.text.trim();
    final tickets = json.decode(widget.ticketsJson);
    final dateStr = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : 'Pendiente';
    final orderId =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // 1. Guardar COMPRA INTEGRAL en Firestore para el Admin
    try {
      await FirebaseFirestore.instance.collection('purchases').add({
        'orderId': orderId,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
        'customerName': targetName,
        'customerEmail': targetEmail,
        'visitDate': dateStr,
        'purchaseDate': FieldValue.serverTimestamp(),
        'items': {
          'general_tickets': tickets['general'] ?? 0,
          'student_tickets': tickets['student'] ?? 0,
          'audio_guides': tickets['audio'] ?? 0,
          'print_3d_height': tickets['print'] ?? 0,
        },
        'totalAmount': widget.total,
        'status': 'completado',
      });
    } catch (e) {
      debugPrint('Error guardando compra integral: $e');
    }

    // 2. Procesar Entradas (Email con QR al usuario y notificación a admin)
    if (tickets['general'] > 0 || tickets['student'] > 0) {
      _sendTicketEmail(targetEmail, targetName, orderId);
    }

    // 3. Procesar Impresión 3D (Notificación específica si existe)
    if (tickets['print'] > 0) {
      _sendPrintRequestEmail(
          targetEmail, targetName, tickets['print'].toString(), orderId);
    }

    // 4. Procesar Audio-Guías (Guardar en colección propia por seguridad)
    if (tickets['audio'] > 0) {
      try {
        await FirebaseFirestore.instance.collection('audio_guides').add({
          'orderId': orderId,
          'userEmail': targetEmail,
          'quantity': tickets['audio'],
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'completado',
        });
      } catch (e) {
        debugPrint('Error guardando audio-guía: $e');
      }
    }
  }

  void _sendTicketEmail(
      String targetEmail, String targetName, String orderId) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TICKET_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isNotEmpty &&
        templateId.isNotEmpty &&
        targetEmail.isNotEmpty) {
      final dateStr = _selectedDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
          : 'Pendiente';
      final ticketId = 'TK-$orderId';

      final qrText =
          '🎟️ ENTRADA DE MUSEO\nID: $ticketId\nVisitante: $targetName\nFecha: $dateStr';
      final qrUrlEncoded = Uri.encodeComponent(qrText);
      final qrUrl = 'https://quickchart.io/qr?text=$qrUrlEncoded&size=400';

      // Guardar en la colección de tickets (AHORA PERMITE SIN FECHA SELECCIONADA)
      try {
        await FirebaseFirestore.instance.collection('tickets').add({
          'ticketId': ticketId,
          'orderId': orderId,
          'visitorName': targetName,
          'visitorEmail': targetEmail,
          'visitDate': dateStr,
          'purchaseDate': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint('Error guardando ticket individual: $e');
      }

      // Solo enviar email si hay fecha, o enviar aviso de que debe elegirla
      _triggerEmailJS(serviceId, templateId, userId, {
        'to_email': targetEmail,
        'name': targetName,
        'ticket_id': ticketId,
        'qr_image_url': qrUrl,
        'visit_date': dateStr,
        'purchase_date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      });
    }
  }

  void _sendPrintRequestEmail(String targetEmail, String targetName,
      String height, String orderId) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isNotEmpty && templateId.isNotEmpty) {
      // Guardar en print_requests para la pestaña de producción del Admin
      try {
        await FirebaseFirestore.instance.collection('print_requests').add({
          'orderId': orderId,
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
          'userEmail': targetEmail,
          'itemName': 'Reproducción 3D ($height mm)',
          'status': 'pendiente',
          'timestamp': FieldValue.serverTimestamp(),
          'notes': 'Pedido integral: $orderId',
        });
      } catch (e) {
        debugPrint('Error guardando petición 3D: $e');
      }

      // Notificación de producción al Admin
      _triggerEmailJS(serviceId, templateId, userId, {
        'to_email': dotenv.env['ADMIN_EMAIL'] ?? targetEmail,
        'name': targetName,
        'item_name': 'Reproducción 3D ($height mm) - Ref: $orderId',
        'user_notes': 'Solicitud de impresión 3D vinculada al pedido $orderId.',
      });
    }
  }

  void _triggerEmailJS(String serviceId, String templateId, String userId,
      Map<String, dynamic> params) async {
    final adminEmailsStr = dotenv.env['ADMIN_EMAIL'] ?? '';
    final List<String> recipients = [params['to_email']];

    // Asegurar que el admin siempre recibe copia de todo
    if (adminEmailsStr.isNotEmpty) {
      final admins = adminEmailsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final admin in admins) {
        if (!recipients.contains(admin)) recipients.add(admin);
      }
    }

    for (final email in recipients.toSet()) {
      try {
        final Map<String, dynamic> finalParams = Map.from(params);
        finalParams['to_email'] = email;

        final response = await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': userId,
            'template_params': finalParams,
          }),
        );

        if (response.statusCode != 200) {
          debugPrint(
              '🚨 Error EmailJS (${response.statusCode}): ${response.body}');
        }
      } catch (e) {
        debugPrint('Error EmailJS to $email: $e');
      }
    }
  }

  Widget _buildWarningBox(ThemeData theme, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.red, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'museum_unavailable'.tr(),
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
