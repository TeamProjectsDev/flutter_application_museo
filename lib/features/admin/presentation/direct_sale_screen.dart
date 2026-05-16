import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/providers/config_provider.dart';
import '../../../core/models/museum_config.dart';

class DirectSaleScreen extends ConsumerStatefulWidget {
  const DirectSaleScreen({super.key});

  @override
  ConsumerState<DirectSaleScreen> createState() => _DirectSaleScreenState();
}

class _DirectSaleScreenState extends ConsumerState<DirectSaleScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  
  DateTime? _selectedDate = DateTime.now();
  bool _isProcessing = false;

  // Carrito de taquilla
  int _generalCount = 0;
  int _studentCount = 0;
  int _audioCount = 0;
  int _printCount = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configState = ref.watch(configProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta Directa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('DATOS DEL VISITANTE'),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Nombre completo', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_emailController, 'Email de contacto', Icons.email),
            const SizedBox(height: 12),
            _buildTextField(_passController, 'Contraseña de acceso', Icons.lock, isObscure: true),
            
            const SizedBox(height: 32),
            _buildSectionTitle('SELECCIÓN DE PRODUCTOS'),
            const SizedBox(height: 16),
            _buildCounterItem('Entrada General', '25.00€', _generalCount, (val) => setState(() => _generalCount = val)),
            _buildCounterItem('Entrada Estudiante', '15.00€', _studentCount, (val) => setState(() => _studentCount = val)),
            _buildCounterItem('Audioguía', '8.00€', _audioCount, (val) => setState(() => _audioCount = val)),
            _buildCounterItem('Acceso 3D / Impresión', '10.00€', _printCount, (val) => setState(() => _printCount = val)),

            const SizedBox(height: 32),
            _buildSectionTitle('FECHA DE VISITA'),
            const SizedBox(height: 16),
            _buildDatePicker(theme, configState.config),

            const SizedBox(height: 40),
            _buildSummaryAndButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCounterItem(String title, String price, int count, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(price, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            IconButton(onPressed: () => count > 0 ? onChanged(count - 1) : null, icon: const Icon(Icons.remove_circle_outline, color: Colors.grey)),
            Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => onChanged(count + 1), icon: const Icon(Icons.add_circle_outline, color: Colors.amber)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme, MuseumConfig? config) {
    final dateStr = _selectedDate == null ? 'Seleccionar Fecha' : DateFormat('dd/MM/yyyy').format(_selectedDate!);
    return InkWell(
      onTap: () => _selectDate(config),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.amber),
            const SizedBox(width: 16),
            Text(dateStr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(MuseumConfig? config) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      // Validar contra config
      final dateKey = DateFormat('yyyy-MM-dd').format(picked);
      final dayConfig = config?.calendarOverrides[dateKey];
      
      if (dayConfig != null && dayConfig.status == DayStatus.closed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El museo está cerrado este día'), backgroundColor: Colors.red));
        return;
      }
      
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildSummaryAndButton(ThemeData theme) {
    final total = (_generalCount * 25) + (_studentCount * 15) + (_audioCount * 8) + (_printCount * 10);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('TOTAL A COBRAR:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${total.toStringAsFixed(2)}€', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: (_isProcessing || total == 0) ? null : _processSale,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isProcessing 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('FINALIZAR VENTA Y ENVIAR TICKET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _processSale() async {
    if (_emailController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, rellena los datos mínimos')));
      return;
    }

    setState(() => _isProcessing = true);
    
    try {
      final ticketId = 'TKT-${DateTime.now().millisecondsSinceEpoch}';
      final totalPeople = _generalCount + _studentCount;

      final data = {
        'ticketId': ticketId,
        'visitorName': _nameController.text.trim().isEmpty ? 'Visitante Taquilla' : _nameController.text.trim(),
        'visitorEmail': _emailController.text.trim(),
        'visitDate': DateFormat('dd/MM/yyyy').format(_selectedDate!),
        'visitDateTimestamp': Timestamp.fromDate(_selectedDate!),
        'purchaseDate': FieldValue.serverTimestamp(),
        'status': 'active',
        'isPhysicalSale': true,
        'totalTickets': totalPeople,
        'items': {
          'general': _generalCount,
          'student': _studentCount,
          'audio': _audioCount,
          'print': _printCount,
        },
      };

      await FirebaseFirestore.instance.collection('tickets').add(data);
      
      // Enviar correo (Reutilizando lógica anterior)
      await _sendEmail(ticketId, _emailController.text.trim(), _nameController.text.trim());

      if (!mounted) return;
      _showSuccessDialog(ticketId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendEmail(String ticketId, String email, String name) async {
    // Lógica de EmailJS simplificada aquí (reutilizando credenciales del .env)
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TICKET_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isEmpty) return;

    try {
      await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': userId,
          'accessToken': dotenv.env['EMAILJS_PRIVATE_KEY'] ?? '',
          'template_params': {
            'to_email': email,
            'name': name,
            'ticket_id': ticketId,
            'qr_image_url': 'https://quickchart.io/qr?text=$ticketId&size=400',
            'visit_date': DateFormat('dd/MM/yyyy').format(_selectedDate!),
          },
        }),
      );
    } catch (_) {}
  }

  void _showSuccessDialog(String ticketId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('VENTA COMPLETADA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('El ticket ha sido generado y enviado por correo.'),
            const SizedBox(height: 8),
            Text('ID: $ticketId', style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          }, child: const Text('VOLVER'))
        ],
      ),
    );
  }
}
