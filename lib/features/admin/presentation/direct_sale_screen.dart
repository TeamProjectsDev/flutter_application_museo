import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _userExists = false;
  bool _isCheckingEmail = false;

  // Carrito de taquilla
  int _generalCount = 0;
  int _studentCount = 0;
  int _audioCount = 0;
  int _printCount = 0;
  String? _selectedPiece;

  final List<String> _pieces = [
    'Mandíbula Humana',
    'Pez Globo Enano',
    'Acropora hyacinthus',
    'Prensa Cocodrilo',
    'Busardo Caminero',
    'Cráneo Humano'
  ];

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    if (email.contains('@') && email.contains('.')) {
      _checkUserExistence(email);
    } else {
      if (_userExists) setState(() => _userExists = false);
    }
  }

  Future<void> _checkUserExistence(String email) async {
    if (_isCheckingEmail) return;
    setState(() => _isCheckingEmail = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _userExists = query.docs.isNotEmpty;
          _isCheckingEmail = false;
        });
      }
    } catch (e) {
      debugPrint('Error comprobando email en Firestore: $e');
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configState = ref.watch(configProvider);
    final config = configState.config;
    final dateKey = _selectedDate == null
        ? ''
        : DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final override = config?.calendarOverrides[dateKey];

    // 🛡️ Lógica idéntica a la web
    bool isAvailable = true;
    String? warning;

    if (config != null) {
      if (!config.isGlobalOpen) {
        isAvailable = false;
        warning = 'MUSEO CERRADO GLOBALMENTE';
      } else if (override != null) {
        if (override.status == DayStatus.closed) {
          isAvailable = false;
          warning = override.reason ?? 'DÍA CERRADO';
        } else if (override.status == DayStatus.fullyBooked) {
          isAvailable = false;
          warning = 'AFORO COMPLETO PARA ESTE DÍA';
        }
      }

      final int requested = _generalCount + _studentCount;
      final int capacity = override?.customCapacity ?? config.maxDailyCapacity;
      if (requested > capacity) {
        isAvailable = false;
        warning = 'SOLICITUD EXCEDE AFORO ($capacity)';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta Directa'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (warning != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red)),
                    child: Row(children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(warning,
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)))
                    ]),
                  ),
                _buildSectionTitle('DATOS DEL VISITANTE'),
                const SizedBox(height: 16),
                _buildTextField(
                    _nameController, 'Nombre completo', Icons.person),
                const SizedBox(height: 12),
                _buildTextField(
                    _emailController, 'Email de contacto', Icons.email),
                if (_isCheckingEmail)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 8),
                    child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                if (_userExists)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text('Usuario Registrado ✓',
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                if (!_userExists)
                  _buildTextField(_passController,
                      'Contraseña de acceso (Opcional)', Icons.lock,
                      isObscure: true),
                const SizedBox(height: 32),
                _buildSectionTitle('SELECCIÓN DE PRODUCTOS'),
                const SizedBox(height: 16),
                _buildCounterItem('Entrada General', '25.00€', _generalCount,
                    (val) {
                  setState(() {
                    _generalCount = val;
                    final maxAllowed = _generalCount + _studentCount;
                    if (_audioCount > maxAllowed) _audioCount = maxAllowed;
                  });
                }),
                _buildCounterItem('Entrada Estudiante', '15.00€', _studentCount,
                    (val) {
                  setState(() {
                    _studentCount = val;
                    final maxAllowed = _generalCount + _studentCount;
                    if (_audioCount > maxAllowed) _audioCount = maxAllowed;
                  });
                }),
                _buildCounterItem('Audioguía', '8.00€', _audioCount, (val) {
                  final maxAllowed = _generalCount + _studentCount;
                  if (val <= maxAllowed) {
                    setState(() => _audioCount = val);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'No puedes asignar más audioguías que entradas ($maxAllowed)'),
                        duration: const Duration(seconds: 1)));
                  }
                }),
                _buildCounterItem('Acceso 3D / Impresión', '10.00€',
                    _printCount, (val) => setState(() => _printCount = val)),
                if (_printCount > 0) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPiece,
                    decoration: InputDecoration(
                      labelText: 'Seleccionar Pieza 3D',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _pieces
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedPiece = v),
                  ),
                ],
                const SizedBox(height: 32),
                _buildSectionTitle('FECHA DE VISITA'),
                const SizedBox(height: 16),
                _buildDatePicker(theme, config),
                const SizedBox(height: 8),
                if (config != null)
                  Text(
                    'Aforo Configurado: ${override?.customCapacity ?? config.maxDailyCapacity} pers.',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                const SizedBox(height: 48),
                _buildTotalSection(theme, !isAvailable),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.amber));
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCounterItem(
      String title, String price, int count, Function(int) onChanged) {
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
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(price,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
                onPressed: () => count > 0 ? onChanged(count - 1) : null,
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.grey)),
            Text('$count',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
                onPressed: () => onChanged(count + 1),
                icon:
                    const Icon(Icons.add_circle_outline, color: Colors.amber)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(ThemeData theme, MuseumConfig? config) {
    final dateStr = _selectedDate == null
        ? 'Seleccionar Fecha'
        : DateFormat('dd/MM/yyyy').format(_selectedDate!);
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
            Text(dateStr,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      final dateKey = DateFormat('yyyy-MM-dd').format(picked);
      final dayConfig = config?.calendarOverrides[dateKey];

      if (dayConfig != null && dayConfig.status == DayStatus.closed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('El museo está cerrado este día'),
            backgroundColor: Colors.red));
        return;
      }

      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildTotalSection(ThemeData theme, bool isBlocked) {
    final total = (_generalCount * 25.0) +
        (_studentCount * 15.0) +
        (_audioCount * 8.0) +
        (_printCount * 10.0);
    final bool hasItems = total > 0;
    final bool canSell =
        !isBlocked && hasItems && _emailController.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL A COBRAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${total.toStringAsFixed(2)}€',
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 28)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (isBlocked || _isProcessing || !canSell)
                  ? null
                  : _processSale,
              icon: const Icon(Icons.check_circle),
              label: const Text('CONFIRMAR VENTA Y EMITIR',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isBlocked ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processSale() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passController.text.trim();
    final name = _nameController.text.trim();

    setState(() => _isProcessing = true);

    try {
      // 1. CREAR CUENTA EN FIREBASE AUTH (Solo si el usuario NO existe y hay contraseña)
      if (!_userExists && password.isNotEmpty) {
        final secondaryApp = await Firebase.initializeApp(
          name: 'DirectSaleApp',
          options: Firebase.app().options,
        );
        try {
          final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
              .createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          // Guardar en Firestore para futuras comprobaciones
          if (userCredential.user != null) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userCredential.user!.uid)
                .set({
              'email': email,
              'name': name,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        } catch (authError) {
          debugPrint('Auth Error (Account may already exist): $authError');
        } finally {
          await secondaryApp.delete();
        }
      }

      final orderId =
          DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      final ticketId = 'TK-$orderId';
      final totalPeople = _generalCount + _studentCount;
      final totalRevenue = (_generalCount * 25.0) +
          (_studentCount * 15.0) +
          (_audioCount * 8.0) +
          (_printCount * 10.0);
      final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate!);

      // 2. Guardar COMPRA INTEGRAL (Para Estadísticas del Admin)
      await FirebaseFirestore.instance.collection('purchases').add({
        'orderId': 'ORD-$orderId',
        'userId': 'physical_sale',
        'customerName': name.isEmpty ? 'Visitante Taquilla' : name,
        'customerEmail': email,
        'visitDate': dateStr,
        'purchaseDate': FieldValue.serverTimestamp(),
        'items': {
          'general_tickets': _generalCount,
          'student_tickets': _studentCount,
          'audio_guides': _audioCount,
          'print_3d_height': _printCount > 0 ? 50 : 0,
          'print_3d_piece': _selectedPiece ?? '',
        },
        'totalAmount': totalRevenue.toStringAsFixed(2),
        'status': 'completado',
        'isPhysical': true,
      });

      // 3. Guardar el Ticket Principal (Para el Escáner)
      await FirebaseFirestore.instance.collection('tickets').add({
        'ticketId': ticketId,
        'orderId': 'ORD-$orderId',
        'visitorName': name.isEmpty ? 'Visitante Taquilla' : name,
        'visitorEmail': email,
        'visitDate': dateStr,
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
          'print_piece': _selectedPiece,
        },
      });

      // 4. Si hay Impresión 3D, registrarla en la cola de producción
      if (_printCount > 0) {
        await FirebaseFirestore.instance.collection('print_requests').add({
          'orderId': 'ORD-$orderId',
          'userId': 'physical_sale',
          'pieceName': _selectedPiece ?? 'Pieza Museo',
          'height': 50,
          'customerName': name.isEmpty ? 'Visitante Taquilla' : name,
          'customerEmail': email,
          'status': 'pendiente',
          'timestamp': FieldValue.serverTimestamp(),
          'notes': 'Venta física en taquilla. Ref: $ticketId',
        });
      }

      // 5. Si hay Audioguías, registrarlas individualmente para que aparezcan en el perfil
      if (_audioCount > 0) {
        for (int i = 0; i < _audioCount; i++) {
          await FirebaseFirestore.instance.collection('audio_guides').add({
            'ticketId': 'AUD-$orderId-$i',
            'orderId': 'ORD-$orderId',
            'userEmail': email,
            'userId': 'physical_sale',
            'visitorName': name.isEmpty ? 'Visitante Taquilla' : name,
            'visitDate': dateStr,
            'visitDateTimestamp': Timestamp.fromDate(_selectedDate!),
            'purchaseDate': FieldValue.serverTimestamp(),
            'status': 'active',
            'quantity': 1,
          });
        }
      }

      // 📧 ENVIAR EMAILS (Entrada + 3D si aplica)
      await _sendTicketsEmail(ticketId, 'ORD-$orderId', email, name, dateStr);

      if (_printCount > 0) {
        await _sendPrintEmail(
            'ORD-$orderId', email, name, _selectedPiece ?? 'Pieza');
      }

      if (!mounted) return;
      _showSuccessDialog(ticketId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendTicketsEmail(String ticketId, String orderId, String email,
      String name, String visitDate) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TICKET_TEMPLATE_ID'] ?? '';
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isEmpty) return;

    final List<String> details = [];
    if (_generalCount > 0) {
      details.add('${'shop_item_general_title'.tr()} x$_generalCount');
    }
    if (_studentCount > 0) {
      details.add('${'shop_item_student_title'.tr()} x$_studentCount');
    }
    if (_audioCount > 0) {
      details.add('${'shop_item_audio_title'.tr()} x$_audioCount');
    }

    await _triggerEmailJS(serviceId, templateId, userId, {
      'to_email': email,
      'from_name': 'app_title'.tr(),
      'subject': 'email_ticket_subject'.tr(args: [orderId]),
      'name': name.isEmpty ? 'Visitante' : name,
      'ticket_id': orderId,
      'qr_image_url': 'https://quickchart.io/qr?text=$ticketId&size=400',
      'visit_date': visitDate,
      'purchase_date': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      'tickets_details': details.join('\n'),
    });
  }

  Future<void> _sendPrintEmail(
      String orderId, String email, String name, String pieceName) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? ''; // El de 3D
    final userId = dotenv.env['EMAILJS_USER_ID'] ?? '';

    if (serviceId.isEmpty || templateId.isEmpty) return;

    await _triggerEmailJS(serviceId, templateId, userId, {
      'to_email': email,
      'name': name.isEmpty ? 'Visitante' : name,
      'item_name': '$pieceName (50mm) - Ref: $orderId',
      'user_notes': 'Venta física en taquilla. Pedido $orderId.',
    });
  }

  Future<void> _triggerEmailJS(String serviceId, String templateId,
      String userId, Map<String, dynamic> params) async {
    final adminEmailsStr = dotenv.env['ADMIN_EMAIL'] ?? '';
    final List<String> recipients = [params['to_email']];

    if (adminEmailsStr.isNotEmpty) {
      final admins = adminEmailsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      for (final admin in admins) {
        if (!recipients.contains(admin)) recipients.add(admin);
      }
    }

    for (final recipient in recipients.toSet()) {
      try {
        final Map<String, dynamic> finalParams = Map.from(params);
        finalParams['to_email'] = recipient;

        await http.post(
          Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'service_id': serviceId,
            'template_id': templateId,
            'user_id': userId,
            'accessToken': dotenv.env['EMAILJS_PRIVATE_KEY'] ?? '',
            'template_params': finalParams,
          }),
        );
      } catch (e) {
        debugPrint('Error enviando email a $recipient: $e');
      }
    }
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
            Text('ID: $ticketId',
                style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('VOLVER'))
        ],
      ),
    );
  }
}
