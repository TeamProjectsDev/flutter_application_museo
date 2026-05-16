import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TicketScannerScreen extends ConsumerStatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  ConsumerState<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends ConsumerState<TicketScannerScreen> {
  int _currentIndex = 0; // 0: Escáner, 1: Venta Directa
  bool _isProcessing = false;
  MobileScannerController controller = MobileScannerController();

  // Controladores para el formulario de venta
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedType = 'all'; // all, entrance, 3d, audio
  int _quantity = 1;

  @override
  void dispose() {
    controller.dispose();
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'admin_scanner_title'.tr() : 'Venta en Taquilla'.tr()),
        backgroundColor: _currentIndex == 0 ? Colors.transparent : theme.colorScheme.surface,
        elevation: 0,
      ),
      extendBodyBehindAppBar: _currentIndex == 0,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildScannerTab(),
          _buildSaleTab(theme),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            controller.start();
          } else {
            controller.stop();
          }
          setState(() => _currentIndex = index);
        },
        selectedItemColor: Colors.amber,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Escanear'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Venta Directa'),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            if (_isProcessing) return;
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _processTicket(barcode.rawValue!);
                break;
              }
            }
          },
        ),
        _buildScannerOverlay(context),
        if (_isProcessing)
          Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildSaleTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar Nueva Venta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Crea una cuenta y ticket instantáneo para el visitante.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Nombre del Visitante', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Contraseña sugerida', prefixIcon: const Icon(Icons.lock), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 24),
          
          const Text('Tipo de Entrada', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Pack Completo (Entrada + 3D + Audio)')),
              DropdownMenuItem(value: 'entrance', child: Text('Entrada General')),
              DropdownMenuItem(value: '3d', child: Text('Acceso 3D solamente')),
              DropdownMenuItem(value: 'audio', child: Text('Audioguía')),
            ],
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Text('Cantidad de personas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null), icon: const Icon(Icons.remove_circle_outline)),
              Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleDirectSale,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isProcessing 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('FINALIZAR VENTA Y GENERAR QR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDirectSale() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email y contraseña son obligatorios')));
      return;
    }

    setState(() => _isProcessing = true);
    final String email = _emailController.text.trim();
    final String password = _passController.text.trim();
    final String name = _nameController.text.trim();

    debugPrint('🔐 Venta directa para $email con pass de ${password.length} caracteres');

    try {
      // 1. Crear el usuario en Firebase de forma aislada
      // Nota: En producción esto se hace mejor vía Cloud Function, pero usaremos FirebaseAdmin o lógica de creación temporal
      // Para esta versión, creamos el registro en Firestore y el usuario podrá loguearse
      
      final String ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch}';
      
      final ticketData = {
        'ticketId': ticketId,
        'visitorName': name.isEmpty ? 'Visitante Taquilla' : name,
        'email': email,
        'status': 'active',
        'purchaseDate': FieldValue.serverTimestamp(),
        'visitDate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'visitDateTimestamp': Timestamp.now(),
        'totalTickets': _quantity,
        'type': _selectedType,
        'isPhysicalSale': true,
      };

      await FirebaseFirestore.instance.collection('tickets').add(ticketData);

      if (!mounted) return;

      // 📧 ENVIAR CORREO VÍA EMAILJS
      _sendConfirmationEmail(email, name, ticketId);

      // 2. Mostrar el QR al administrador para que el cliente lo tenga
      _showQrResult(ticketId, name);
      
      // Limpiar formulario
      _emailController.clear();
      _passController.clear();
      _nameController.clear();
      setState(() => _quantity = 1);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error en la venta: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showQrResult(String code, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('VENTA COMPLETADA', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enséñale este código al visitante:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$code',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 20),
            Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text('Visitante: $name', style: const TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('LISTO'),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Container(color: Colors.black54)),
        Row(
          children: [
            Expanded(child: Container(color: Colors.black54)),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Expanded(child: Container(color: Colors.black54)),
          ],
        ),
        Expanded(
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Text(
                  'admin_scanner_hint'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Icon(Icons.qr_code_scanner, color: Colors.amber, size: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _processTicket(String code) async {
    setState(() => _isProcessing = true);
    // 🛑 Pausar la cámara para que no siga consumiendo recursos ni escaneando por detrás
    controller.stop();
    
    try {
      // 🔍 Buscar ticket en Firestore
      DocumentSnapshot? ticketDoc;

      // 1. Intentar buscar en la colección de 'tickets'
      var queryTickets = await FirebaseFirestore.instance
          .collection('tickets')
          .where('ticketId', isEqualTo: code)
          .get();

      if (queryTickets.docs.isNotEmpty) {
        ticketDoc = queryTickets.docs.first;
      } else {
        // 2. Intentar buscar en la colección de 'audio_guides'
        var queryAudio = await FirebaseFirestore.instance
            .collection('audio_guides')
            .where('ticketId', isEqualTo: code)
            .get();
        
        if (queryAudio.docs.isNotEmpty) {
          ticketDoc = queryAudio.docs.first;
        } else {
          // 3. Búsqueda por ID de documento directo (fallback para antiguos)
          try {
            final docTicket = await FirebaseFirestore.instance.collection('tickets').doc(code).get();
            if (docTicket.exists) {
              ticketDoc = docTicket;
            } else {
              final docAudio = await FirebaseFirestore.instance.collection('audio_guides').doc(code).get();
              if (docAudio.exists) ticketDoc = docAudio;
            }
          } catch (_) {}
        }
      }

      if (ticketDoc == null) {
        await _showResultDialog('admin_scanner_error_not_found'.tr(), isError: true);
        return;
      }

      final data = ticketDoc.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'active';

      // 🕒 Comprobar si está caducada
      DateTime? visitDate;
      if (data['visitDateTimestamp'] != null) {
        visitDate = (data['visitDateTimestamp'] as Timestamp).toDate();
      } else if (data['visitDate'] != null) {
        try {
          final parts = (data['visitDate'] as String).split('/');
          if (parts.length == 3) {
            visitDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } catch (_) {}
      }

      bool isExpired = false;
      bool isFuture = false;
      
      if (visitDate != null) {
        final now = DateTime.now();
        final startOfVisitDay = DateTime(visitDate.year, visitDate.month, visitDate.day, 0, 0, 0);
        final endOfVisitDay = DateTime(visitDate.year, visitDate.month, visitDate.day, 23, 59, 59);
        
        if (now.isAfter(endOfVisitDay)) {
          isExpired = true;
        } else if (now.isBefore(startOfVisitDay)) {
          isFuture = true;
        }
      }

      if (status == 'used') {
        FirebaseAnalytics.instance.logEvent(name: 'admin_scan_error', parameters: {'reason': 'already_used'});
        await _showResultDialog('admin_scanner_error_used'.tr(), isError: true, data: data, status: status);
      } else if (isExpired) {
        FirebaseAnalytics.instance.logEvent(name: 'admin_scan_error', parameters: {'reason': 'expired'});
        await _showResultDialog('tickets_status_expired'.tr(), isError: true, data: data, status: 'expired');
      } else if (isFuture) {
        // ⚠️ AVISO DE DÍA FUTURO (No se marca como usada)
        FirebaseAnalytics.instance.logEvent(name: 'admin_scan_warning', parameters: {'reason': 'future_date'});
        await _showResultDialog(
          'admin_scanner_warning_future'.tr(), 
          isError: false, 
          isWarning: true,
          data: data, 
          status: 'future'
        );
      } else {
        // ✅ Validar y marcar como usado (SÓLO SI ES HOY)
        final isAudio = ticketDoc.reference.path.contains('audio_guides');
        await ticketDoc.reference.update({
          'status': 'used',
          'usedAt': FieldValue.serverTimestamp(),
        });
        
        FirebaseAnalytics.instance.logEvent(
          name: isAudio ? 'admin_audio_guide_validated' : 'admin_ticket_validated',
          parameters: {'visitor': data['visitorName'] ?? 'unknown'},
        );
        
        await _showResultDialog('admin_scanner_success'.tr(), isError: false, data: data, isAudio: isAudio, status: 'active');
      }
    } catch (e) {
      FirebaseAnalytics.instance.logEvent(name: 'admin_scan_error', parameters: {'reason': 'exception', 'error': e.toString()});
      await _showResultDialog('${'common_error'.tr()}: $e', isError: true);
    } finally {
      // 🔄 Reiniciar la cámara para el siguiente visitante
      await controller.start();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showResultDialog(String message, {required bool isError, bool isWarning = false, Map<String, dynamic>? data, bool isAudio = false, String? status}) async {
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              isError ? Icons.error_outline : (isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline),
              color: isError ? Colors.red : (isWarning ? Colors.orange : Colors.green),
              size: 60,
            ),
            const SizedBox(height: 8),
            Text(
              isError ? 'common_error'.tr() : (isWarning ? 'common_attention'.tr() : 'admin_scanner_success'.tr()),
              style: TextStyle(color: isError ? Colors.red : (isWarning ? Colors.orange : Colors.green), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data != null) ...[
              const Divider(),
              _infoDetail(Icons.person, data['visitorName'] ?? data['userName'] ?? 'common_visitor'.tr()),
              _infoDetail(isAudio ? Icons.headset_mic : Icons.confirmation_number, isAudio ? 'common_audio_guide'.tr() : 'common_museum_entrance'.tr()),
              
              // 👥 CANTIDAD DINÁMICA (Especial Grupos 2026)
              _infoDetail(
                Icons.groups, 
                'admin_scanner_total_people'.tr(args: [(data['totalTickets'] ?? data['quantity'] ?? 1).toString()]),
                isHighlighted: true
              ),

              // 📊 DESGLOSE DE ITEMS
              if (data['items'] != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Column(
                    children: (data['items'] as Map<String, dynamic>).entries.map((e) {
                      if (e.value == 0) return const SizedBox.shrink();
                      String label = e.key;
                      if (label == 'general') label = 'admin_scanner_label_general'.tr();
                      if (label == 'student') label = 'admin_scanner_label_student'.tr();
                      if (label == 'audio') label = 'admin_scanner_label_audio'.tr();
                      return _infoDetail(Icons.arrow_right, '$label: x${e.value}', isSmall: true);
                    }).toList(),
                  ),
                ),
              ],

              _infoDetail(Icons.calendar_today, '${'admin_scanner_visit_date'.tr()}: ${data['visitDate'] ?? '---'}'),
              _infoDetail(
                Icons.info_outline, 
                '${'admin_v2_change_status'.tr().split(' ')[0]}: ${status == 'used' ? 'admin_scanner_status_used'.tr() : (status == 'future' ? 'admin_scanner_status_future'.tr() : 'admin_scanner_status_valid'.tr())}',
                color: status == 'used' ? Colors.red : (status == 'future' ? Colors.orange : Colors.green)
              ),
              const Divider(),
            ],
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: isError ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('map_close'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoDetail(IconData icon, String text, {bool isHighlighted = false, bool isSmall = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: isSmall ? 12 : 18, color: color ?? Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text, 
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlighted ? 18 : (isSmall ? 12 : 14),
              color: color,
            )
          )
        ),
      ],
    ),
  );

  Future<void> _sendConfirmationEmail(String targetEmail, String targetName, String ticketId) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TICKET_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isEmpty || templateId.isEmpty) return;

    final qrUrl = 'https://quickchart.io/qr?text=$ticketId&size=400';
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    await _triggerEmailJS(serviceId, templateId, userId, {
      'to_email': targetEmail,
      'from_name': 'Museo Padre Suárez',
      'subject': 'Tu Entrada al Museo - $ticketId',
      'name': targetName,
      'qr_image_url': qrUrl,
      'ticket_id': ticketId,
      'visit_date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'purchase_date': dateStr,
      'tickets_details': 'Venta Directa en Taquilla - $_selectedType (x$_quantity)',
    });
  }

  Future<void> _triggerEmailJS(String serviceId, String templateId, String userId, Map<String, dynamic> params) async {
    try {
      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'accessToken': dotenv.env['EMAILJS_PRIVATE_KEY'] ?? '',
          'template_params': params,
        }),
      );
    } catch (e) {
      debugPrint('Error EmailJS: $e');
    }
  }
}
