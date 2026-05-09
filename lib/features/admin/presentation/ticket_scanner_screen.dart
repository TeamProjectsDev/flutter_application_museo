import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketScannerScreen extends ConsumerStatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  ConsumerState<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends ConsumerState<TicketScannerScreen> {
  bool _isProcessing = false;
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('admin_scanner_title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 📷 Visor de Cámara
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

          // 🔳 Overlay de escaneo
          _buildScannerOverlay(context),

          // 🛡️ Indicador de procesamiento
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
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
      if (visitDate != null) {
        final now = DateTime.now();
        final endOfVisitDay = DateTime(visitDate.year, visitDate.month, visitDate.day, 23, 59, 59);
        if (now.isAfter(endOfVisitDay)) {
          isExpired = true;
        }
      }

      if (status == 'used') {
        await _showResultDialog('admin_scanner_error_used'.tr(), isError: true, data: data, status: status);
      } else if (isExpired) {
        await _showResultDialog('tickets_status_expired'.tr(), isError: true, data: data, status: 'expired');
      } else {
        // ✅ Validar y marcar como usado
        await ticketDoc.reference.update({
          'status': 'used',
          'usedAt': FieldValue.serverTimestamp(),
        });
        await _showResultDialog('admin_scanner_success'.tr(), isError: false, data: data, isAudio: ticketDoc.reference.path.contains('audio_guides'), status: status);
      }
    } catch (e) {
      await _showResultDialog('Error: $e', isError: true);
    } finally {
      // 🔄 Reiniciar la cámara para el siguiente visitante
      await controller.start();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showResultDialog(String message, {required bool isError, Map<String, dynamic>? data, bool isAudio = false, String? status}) async {
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
              size: 60,
            ),
            const SizedBox(height: 8),
            Text(
              isError ? 'Error' : 'admin_scanner_success'.tr(),
              style: TextStyle(color: isError ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data != null) ...[
              const Divider(),
              _infoDetail(Icons.person, data['visitorName'] ?? data['userName'] ?? 'Visitante'),
              _infoDetail(isAudio ? Icons.headset_mic : Icons.confirmation_number, isAudio ? 'Audio-guía' : 'Entrada Museo'),
              _infoDetail(Icons.people, 'Cantidad: ${data['quantity'] ?? 1}'),
              _infoDetail(Icons.calendar_today, 'Fecha: ${data['visitDate'] ?? '---'}'),
              _infoDetail(Icons.info_outline, 'Estado: ${status == 'used' ? 'USADA (ERROR)' : 'ACTIVA (VALIDADA)'}'),
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

  Widget _infoDetail(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    ),
  );
}
