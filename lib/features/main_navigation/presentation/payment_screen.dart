import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/web_utils.dart';
import '../../../core/providers/config_provider.dart';
import '../../../core/models/museum_config.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String total;
  final String subtotal;
  final String fees;
  final String ticketsJson;
  final bool stripeSuccess;
  final String? customerName;
  final String? customerEmail;
  final String? stripeDate;
  final String? printPieceName;

  const PaymentScreen({
    super.key,
    this.total = "0",
    this.subtotal = "0",
    this.fees = "0",
    this.ticketsJson = "{}",
    this.stripeSuccess = false,
    this.customerName,
    this.customerEmail,
    this.stripeDate,
    this.printPieceName,
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
  String? _recoveredTicketsJson;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // ⚡ Activamos el cargador inmediatamente si venimos de Stripe para evitar parpadeos
    if (widget.stripeSuccess) {
      _isProcessing = true;
    }
    
    FirebaseAnalytics.instance.logEvent(name: 'view_payment_screen');
    
    // 🕵️‍♂️ DETECCIÓN DE ÉXITO (Doble seguridad: Parámetro o URL real)
    bool isActuallySuccess = widget.stripeSuccess;
    if (kIsWeb) {
      final currentUrl = Uri.base.toString();
      if (currentUrl.contains('payment/success')) {
        isActuallySuccess = true;
      }
    }
    final isCancel = kIsWeb && Uri.base.toString().contains('payment/cancel');

    if (isCancel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El pago fue cancelado o no se pudo completar. Inténtalo de nuevo.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }

    debugPrint('📱 [PaymentScreen] Inicializada con éxito=$isActuallySuccess');
    if (isActuallySuccess) {
      // Eliminamos la llamada directa aquí para usar solo la de addPostFrameCallback
    }

    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? '';
    }

    // 🔄 RECUPERAR DATOS TRAS VOLVER DE STRIPE
    if (widget.customerName != null) {
      _nameController.text = Uri.decodeComponent(widget.customerName!);
    }
    if (widget.customerEmail != null) {
      _emailController.text = Uri.decodeComponent(widget.customerEmail!);
    }

    // 🔄 RECUPERAR FECHA
    if (widget.stripeDate != null && widget.stripeDate!.isNotEmpty) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.stripeDate!);
      } catch (e) {
        debugPrint('Error parseando fecha: $e');
      }
    }

    // 🚀 SI VOLVEMOS DE STRIPE CON ÉXITO
    if (widget.stripeSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleStripeSuccess();
      });
    }
  }

  void _handleStripeSuccess() async {
    // Ya no mostramos diálogo manual aquí, usamos el velo de carga del Stack

    // 📦 RECUPERAR DATOS DE LA CAJA FUERTE
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('pending_name');
    final savedEmail = prefs.getString('pending_email');
    final savedDate = prefs.getString('pending_date');
    final savedTotal = prefs.getString('pending_total');
    // final savedTickets = prefs.getString('pending_tickets'); // Eliminado por no usarse aquí

    final savedPrintPiece = prefs.getString('pending_print_piece');
    if (savedName != null) _nameController.text = savedName;
    if (savedEmail != null) _emailController.text = savedEmail;
    if (savedDate != null && savedDate.isNotEmpty) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(savedDate);
      } catch (e) {
        debugPrint('Error parseando fecha guardada: $e');
      }
    }
    
    debugPrint('👉 [PaymentScreen] Datos recuperados: $savedName, $savedEmail, Total=$savedTotal, Pieza=$savedPrintPiece, Fecha=$savedDate');

    // Procesamos el pedido de forma asíncrona
    Future.delayed(const Duration(seconds: 1), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('pending_name');
        final savedEmail = prefs.getString('pending_email');
        final savedTotal = prefs.getString('pending_total');
        final savedTickets = prefs.getString('pending_tickets');
        final savedDate = prefs.getString('pending_date');

        // 🔐 CERROJO DE SEGURIDAD: Si estamos en éxito pero no hay rastro del pedido en la "caja fuerte"
        // es que alguien ha intentado entrar escribiendo la URL a mano.
        if (widget.stripeSuccess && savedTotal == null && savedName == null) {
          debugPrint('🚨 [Seguridad] Intento de bypass detectado. Redirigiendo...');
          if (mounted) {
             context.go('/shop');
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Acceso no autorizado. No se encontró ningún pago pendiente.'), backgroundColor: Colors.red),
             );
          }
          return;
        }

        // Actualizamos el estado para que la pantalla se dibuje con los datos recuperados
        if (mounted && savedTotal != null) {
          setState(() {
            _recoveredTicketsJson = savedTickets;
            _nameController.text = savedName ?? "";
            _emailController.text = savedEmail ?? "";
            if (savedDate != null && savedDate.isNotEmpty) {
              _selectedDate = DateFormat('yyyy-MM-dd').parse(savedDate);
            }
          });
        }

        // Usamos los datos guardados si los widgets vienen vacíos (por el recargo de página)
        final effectiveTotal = savedTotal ?? widget.total;
        final effectiveTickets = savedTickets ?? widget.ticketsJson;

        await _processOrderWithData(effectiveTotal, effectiveTickets);
        
        // Limpiamos la caja fuerte después de usarla
        await prefs.clear();

      } catch (e) {
        debugPrint('❌ Error en el proceso automático: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
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
    
    // 🛡️ Blindaje de datos: Priorizamos lo que hay en los controladores o lo recuperado
    // para que la pantalla no se vea vacía ($0.00) tras el refresco de Stripe
    Map<String, dynamic> tickets = {};

    try {
      final String sourceJson = (_recoveredTicketsJson != null && _recoveredTicketsJson!.length > 5)
          ? _recoveredTicketsJson!
          : (widget.ticketsJson.length > 5 ? widget.ticketsJson : "{}");
      tickets = json.decode(sourceJson);
    } catch (_) {
      tickets = {};
    }
    
    final bool isOnly3D = (int.tryParse(tickets['general']?.toString() ?? '0') ?? 0) == 0 &&
                         (int.tryParse(tickets['student']?.toString() ?? '0') ?? 0) == 0;
    
    final isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('checkout_title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing 
            ? null 
            : () {
                if (GoRouter.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: _isProcessing ? const NeverScrollableScrollPhysics() : null,
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
              _buildPaymentForm(theme, isOnly3D),

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

                  // 🚩 Comprobación 3: Aforo Máximo (Priorizar aforo especial del día)
                  Map<String, dynamic> ticketsMap = {};
                  try {
                    ticketsMap = json.decode(widget.ticketsJson.isEmpty ? '{}' : widget.ticketsJson);
                  } catch (_) {}

                  final int gReq = int.tryParse(ticketsMap['general']?.toString() ?? '0') ?? 0;
                  final int sReq = int.tryParse(ticketsMap['student']?.toString() ?? '0') ?? 0;
                  final int totalRequested = gReq + sReq;
                  
                  debugPrint('📊 [PaymentScreen] Comprobando aforo: Solicitados=$totalRequested (G:$gReq, S:$sReq)');

                  if (config != null) {
                    int effectiveCapacity = config.maxDailyCapacity;
                    
                    // Si el día tiene un aforo personalizado, usamos ese
                    if (_selectedDate != null) {
                      final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate!);
                      final override = config.calendarOverrides[dateKey];
                      if (override != null && override.customCapacity != null) {
                        effectiveCapacity = override.customCapacity!;
                      }
                    }

                    debugPrint('🏛️ [PaymentScreen] Aforo efectivo para hoy: $effectiveCapacity');

                    if (totalRequested > effectiveCapacity) {
                      debugPrint('🚨 [PaymentScreen] ¡AFORO EXCEDIDO!');
                      return _buildWarningBox(
                        theme, 
                        'museum_capacity_exceeded'.tr(args: [effectiveCapacity.toString()]), 
                        Icons.groups_outlined
                      );
                    }
                  }

                  // 🚩 Comprobación 4: Audioguías vs Visitantes
                  final int audioRequested = int.tryParse(ticketsMap['audio']?.toString() ?? '0') ?? 0;
                  if (audioRequested > totalRequested && totalRequested > 0) {
                    return _buildWarningBox(
                      theme, 
                      'shop_error_audio_limit'.tr(args: [totalRequested.toString()]), 
                      Icons.headset_mic_outlined
                    );
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (paymentState.isLoading ||
                              _isProcessing ||
                              _nameController.text.trim().isEmpty ||
                              !_emailController.text.contains('@') ||
                              (!isOnly3D && _selectedDate == null && !isTester))
                          ? null
                          : _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.black,
                      ),
                      child: (paymentState.isLoading || _isProcessing)
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
                        TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
      if (_isProcessing)
        Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ],
  ),
);
  }

  Widget _buildPaymentForm(ThemeData theme, bool isOnly3D) {
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
            _buildSimpleField(controller: _nameController, hint: 'p. ej. Alberto Ortiz'),
            const SizedBox(height: 20),
            _buildFieldLabel('checkout_email'.tr()),
            _buildSimpleField(
                controller: _emailController, hint: 'ejemplo@correo.com'),
            if (!isOnly3D) ...[
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
                  .withValues(alpha: 0.6), // Subido de 0.4 a 0.6 para legibilidad
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
          if ((int.tryParse(tickets['general']?.toString() ?? '0') ?? 0) > 0)
            _summaryRow(
                '${'shop_item_general_title'.tr()} x${tickets['general']}',
                ((int.tryParse(tickets['general']?.toString() ?? '0') ?? 0) * 25.0).toStringAsFixed(2)),
          if ((int.tryParse(tickets['student']?.toString() ?? '0') ?? 0) > 0)
            _summaryRow(
                '${'shop_item_student_title'.tr()} x${tickets['student']}',
                ((int.tryParse(tickets['student']?.toString() ?? '0') ?? 0) * 15.0).toStringAsFixed(2)),
          if ((int.tryParse(tickets['audio']?.toString() ?? '0') ?? 0) > 0)
            _summaryRow('${'shop_item_audio_title'.tr()} x${tickets['audio']}',
                ((int.tryParse(tickets['audio']?.toString() ?? '0') ?? 0) * 8.0).toStringAsFixed(2)),
          if ((int.tryParse(tickets['print']?.toString() ?? '0') ?? 0) > 0)
            _summaryRow('3D Print (${widget.printPieceName ?? 'Pieza'}) ${tickets['print']}mm',
                (10.0 + (int.tryParse(tickets['print']?.toString() ?? '0') ?? 0) * 0.2).toStringAsFixed(2)),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: isSmall ? 0.5 : 0.8), // Subido de 0.3/0.7
                    fontSize: isSmall ? 11 : 13)),
          ),
          Text('\$$value',
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: isSmall ? FontWeight.normal : FontWeight.w500,
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

      // 📦 GUARDAR DATOS EN LA "CAJA FUERTE" (Memoria local)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_name', _nameController.text.trim());
      await prefs.setString('pending_email', _emailController.text.trim());
      await prefs.setString('pending_date', _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : "");
      await prefs.setString('pending_total', widget.total);
      await prefs.setString('pending_subtotal', widget.subtotal);
      await prefs.setString('pending_fees', widget.fees);
      await prefs.setString('pending_tickets', widget.ticketsJson);
      if (widget.printPieceName != null) {
        await prefs.setString('pending_print_piece', widget.printPieceName!);
      }

      final stripeUrl = await StripeService().createCheckoutSession(
        productName: 'Reserva Museo Padre Suárez',
        amountInCents: (double.parse(widget.total) * 100).toInt(),
        currency: 'eur',
        // 🔗 URL de retorno segura vinculada a tu proyecto Firebase
        successUrl: kIsWeb 
            ? '${Uri.base.origin}/#/payment/success' 
            : 'https://${dotenv.env['FIREBASE_PROJECT_ID']}.web.app/#/payment/success',
        cancelUrl: kIsWeb 
            ? '${Uri.base.origin}/#/payment/cancel' 
            : 'https://${dotenv.env['FIREBASE_PROJECT_ID']}.web.app/#/payment/cancel',
      );

      ref.read(paymentProvider.notifier).setLoading(false);

      if (stripeUrl != null && stripeUrl.isNotEmpty) {
        debugPrint('🛫 [PaymentScreen] Redirigiendo a Stripe: $stripeUrl');
        if (kIsWeb) {
          // En la web, forzamos el cambio en la misma pestaña mediante utilidad segura
          await redirectToUrl(stripeUrl);
        } else {
          // En móviles usamos el lanzador estándar
          await launchUrlString(stripeUrl, mode: LaunchMode.externalApplication);
        }
      } else {
        debugPrint('🚨 [PaymentScreen] Error: No se pudo generar la URL de Stripe');
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
        title: Text('shop_tester_title'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'shop_tester_desc'.tr(),
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
                  Text('shop_tester_cancel'.tr(), style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processOrder();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('shop_tester_success'.tr()),
                  backgroundColor: Colors.green));
              context.pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                foregroundColor: Colors.green),
            child: Text('shop_tester_confirm'.tr()),
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

  Future<void> _processOrder() async {
    await _processOrderWithData(widget.total, widget.ticketsJson);
  }

  Future<void> _processOrderWithData(String total, String ticketsJson) async {
    final targetEmail = _emailController.text.trim();
    final targetName = _nameController.text.trim();
    final tickets = json.decode(ticketsJson);
    final dateStr = _selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
        : 'Pendiente';
    final orderId =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    debugPrint('🚀 Iniciando proceso de pedido: $orderId');

    setState(() => _isProcessing = true);

    try {
      // 📦 RECUPERAR EL NOMBRE DE LA PIEZA DE LA CAJA FUERTE (Prioridad máxima)
      final prefs = await SharedPreferences.getInstance();
      final finalPieceName = prefs.getString('pending_print_piece') ?? widget.printPieceName ?? 'Pieza Museo';
      
      debugPrint('📦 [PaymentScreen] Nombre final de la pieza para Firestore: $finalPieceName');

      // 1. Guardar COMPRA INTEGRAL en Firestore para el Admin
      await FirebaseFirestore.instance.collection('purchases').add({
        'orderId': orderId,
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
        'customerName': targetName,
        'customerEmail': targetEmail,
        'visitDate': dateStr,
        'purchaseDate': FieldValue.serverTimestamp(),
        'items': {
          'general_tickets': int.tryParse(tickets['general']?.toString() ?? '0') ?? 0,
          'student_tickets': int.tryParse(tickets['student']?.toString() ?? '0') ?? 0,
          'audio_guides': int.tryParse(tickets['audio']?.toString() ?? '0') ?? 0,
          'print_3d_height': int.tryParse(tickets['print']?.toString() ?? '0') ?? 0,
          'print_3d_piece': finalPieceName,
        },
        'totalAmount': total,
        'status': 'completado',
      });
      debugPrint('✅ Compra guardada en Firestore');

      // 2. Procesar Entradas (Email con QR al usuario y notificación a admin)
      final int generalCount = int.tryParse(tickets['general']?.toString() ?? '0') ?? 0;
      final int studentCount = int.tryParse(tickets['student']?.toString() ?? '0') ?? 0;
      final int printCount = int.tryParse(tickets['print']?.toString() ?? '0') ?? 0;
      final int audioCount = int.tryParse(tickets['audio']?.toString() ?? '0') ?? 0;

      if (generalCount > 0 || studentCount > 0) {
        debugPrint('🎟️ Procesando tickets...');
        await _sendTicketEmail(targetEmail, targetName, orderId, tickets);
      }

          // 3. Procesar Impresión 3D (Registro en cola y notificación)
          if (printCount > 0) {
            debugPrint('🖨️ Procesando impresión 3D...');
            final prefs = await SharedPreferences.getInstance();
            final savedPieceName = prefs.getString('pending_print_piece') ?? widget.printPieceName ?? 'Pieza Museo';

            await FirebaseFirestore.instance.collection('print_requests').add({
              'orderId': orderId,
              'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
              'pieceName': savedPieceName,
              'height': printCount,
              'customerName': targetName,
              'customerEmail': targetEmail,
              'status': 'pendiente',
              'timestamp': FieldValue.serverTimestamp(),
              'notes': 'Tamaño: ${printCount}mm | Ref: $orderId', // 📐 Añadida la altura a las notas
            });

          await _sendPrintRequestEmail(
              targetEmail, targetName, printCount.toString(), orderId, savedPieceName);
        }

      // 4. Procesar Audio-Guías (Guardar en colección propia por seguridad)
      if (audioCount > 0) {
        try {
          await FirebaseFirestore.instance.collection('audio_guides').add({
            'orderId': orderId,
            'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest',
            'userEmail': targetEmail,
            'quantity': audioCount,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'active',
          });
          debugPrint('🎧 Audioguía guardada en Firestore');
        } catch (e) {
          debugPrint('Error guardando audio-guía: $e');
        }
      }

      // 🎉 ÉXITO FINAL
      if (mounted) {
        debugPrint('🎊 ¡Proceso completado con éxito! Mostrando factura...');
        setState(() => _isProcessing = false);
        
        // 🚀 USAR POST FRAME CALLBACK PARA EVITAR ERRORES DE NAVEGACIÓN
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSuccessDialog(orderId, total, tickets, dateStr);
          }
        });
      }

    } catch (e) {
      debugPrint('❌ ERROR en el proceso de pedido: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        
        // 💡 Si el error es de permisos en 3D_prints o audioguías, pero la compra se guardó,
        // podríamos considerarlo un éxito parcial, pero para seguridad del usuario,
        // mostramos el error y le pedimos que contacte con soporte.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        // Limpiamos la caja fuerte para evitar duplicados
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('pending_name');
        await prefs.remove('pending_email');
        await prefs.remove('pending_total');
        await prefs.remove('pending_tickets');
        await prefs.remove('pending_date');
      }
    }
  }

  Future<void> _sendTicketEmail(String targetEmail, String targetName,
      String orderId, Map<String, dynamic> tickets) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TICKET_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isNotEmpty &&
        templateId.isNotEmpty &&
        targetEmail.isNotEmpty) {
      final List<String> ticketsList = [];
      final int general = int.tryParse(tickets['general']?.toString() ?? '0') ?? 0;
      final int student = int.tryParse(tickets['student']?.toString() ?? '0') ?? 0;
      final int audio = int.tryParse(tickets['audio']?.toString() ?? '0') ?? 0;

      if (general > 0) {
        ticketsList.add('$general x Entrada General');
      }
      if (student > 0) {
        ticketsList.add('$student x Entrada Estudiante/Reducida');
      }
      if (audio > 0) {
        ticketsList.add('$audio x Audioguía');
      }

      final dateStr = _selectedDate != null
          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
          : 'Pendiente';
      final ticketId = 'TK-$orderId';

      final qrText =
          '🎟️ ENTRADA DE MUSEO\nID: $ticketId\nVisitante: $targetName\nFecha: $dateStr';
      final qrUrlEncoded = Uri.encodeComponent(qrText);
      final qrUrl = 'https://quickchart.io/qr?text=$qrUrlEncoded&size=400';

      try {
        await FirebaseFirestore.instance.collection('tickets').add({
          'ticketId': ticketId,
          'orderId': orderId,
          'userId': FirebaseAuth.instance.currentUser?.uid ?? 'guest', // CRÍTICO: Añadido userId
          'visitorName': targetName,
          'visitorEmail': targetEmail,
          'visitDate': dateStr,
          'visitDateTimestamp': _selectedDate != null 
              ? Timestamp.fromDate(_selectedDate!) 
              : null, // Guardado para lógica de 24h
          'purchaseDate': FieldValue.serverTimestamp(),
          'status': 'active', // Estado inicial
        });
      } catch (e) {
        debugPrint('Error guardando ticket individual: $e');
      }

      await _triggerEmailJS(serviceId, templateId, userId, {
        'to_email': targetEmail,
        'from_name': 'Museo Padre Suárez',
        'to_name': targetName,
        'order_id': orderId,
        'visit_date': dateStr,
        'tickets_details': ticketsList.join('\n'),
        'qr_data': qrUrl,
      });
    }
  }

  Future<void> _sendPrintRequestEmail(String targetEmail, String targetName,
      String height, String orderId, String pieceName) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isNotEmpty && templateId.isNotEmpty) {
      // 🕵️‍♂️ ELIMINADO EL GUARDADO DUPLICADO AQUÍ (YA SE HACE EN LA FUNCIÓN PRINCIPAL)

      // Notificación de producción al Admin con el nombre real de la pieza
      await _triggerEmailJS(serviceId, templateId, userId, {
        'to_email': dotenv.env['ADMIN_EMAIL'] ?? targetEmail,
        'name': targetName,
        'item_name': '$pieceName (${height}mm) - Ref: $orderId',
        'user_notes': 'Solicitud de impresión 3D para $pieceName. Altura: ${height}mm. Pedido $orderId.',
      });
    }
  }

  Future<void> _triggerEmailJS(String serviceId, String templateId, String userId,
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

  void _showSuccessDialog(String orderId, String total,
      Map<String, dynamic> tickets, String visitDate) {
    final theme = Theme.of(context);
    final goldColor = const Color(0xFFEBC154);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Colors.green, size: 80),
              const SizedBox(height: 16),
              Text(
                'invoice_title'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${'invoice_order_id'.tr()} $orderId',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildInvoiceRow('invoice_visit_date'.tr(), visitDate, theme,
                        isBold: true),
                    const Divider(height: 24),
                    ..._buildInvoiceItems(tickets, theme),
                    const Divider(height: 24),
                    _buildInvoiceRow('invoice_total_paid'.tr(), '$total €', theme,
                        color: goldColor, isBold: true, fontSize: 18),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'invoice_email_notice'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'invoice_back_home'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInvoiceItems(
      Map<String, dynamic> tickets, ThemeData theme) {
    final List<Widget> items = [];
    final int general = int.tryParse(tickets['general']?.toString() ?? '0') ?? 0;
    final int student = int.tryParse(tickets['student']?.toString() ?? '0') ?? 0;
    final int audio = int.tryParse(tickets['audio']?.toString() ?? '0') ?? 0;
    final int print3d = int.tryParse(tickets['print']?.toString() ?? '0') ?? 0;

    if (general > 0) items.add(_buildInvoiceRow('shop_item_general_title'.tr(), 'x$general', theme));
    if (student > 0) items.add(_buildInvoiceRow('shop_item_student_title'.tr(), 'x$student', theme));
    if (audio > 0) items.add(_buildInvoiceRow('shop_item_audio_title'.tr(), 'x$audio', theme));
    if (print3d > 0) items.add(_buildInvoiceRow('admin_v2_label_prints'.tr(), 'x1', theme));

    return items;
  }

  Widget _buildInvoiceRow(String label, String value, ThemeData theme,
      {Color? color, bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
              )),
          Text(value,
              style: TextStyle(
                color: color ?? theme.colorScheme.onSurface,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: fontSize,
              )),
        ],
      ),
    );
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
