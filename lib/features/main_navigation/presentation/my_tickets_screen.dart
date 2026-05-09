import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rxdart/rxdart.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  Stream<List<DocumentSnapshot>>? _ticketsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('🔍 [TICKETS] No hay usuario logueado');
      return;
    }

    final controller = BehaviorSubject<List<DocumentSnapshot>>.seeded([]);
    final Map<String, List<DocumentSnapshot>> resultsMap = {};

    void updateResults(String key, List<DocumentSnapshot> docs) {
      resultsMap[key] = docs;
      final allDocs = resultsMap.values.expand((l) => l).toList();
      
      final seenIds = <String>{};
      final uniqueDocs = allDocs.where((doc) {
        if (seenIds.contains(doc.id)) return false;
        seenIds.add(doc.id);
        
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'active';
        return status != 'used';
      }).toList();
      
      if (!controller.isClosed) controller.add(uniqueDocs);
    }

    // Escuchas independientes
    FirebaseFirestore.instance.collection('tickets').where('visitorEmail', isEqualTo: user.email).snapshots().listen(
      (s) => updateResults('t_email', s.docs),
    );

    FirebaseFirestore.instance.collection('tickets').where('userId', isEqualTo: user.uid).snapshots().listen(
      (s) => updateResults('t_id', s.docs),
    );

    FirebaseFirestore.instance.collection('audio_guides').where('userEmail', isEqualTo: user.email).snapshots().listen(
      (s) => updateResults('a_email', s.docs),
    );

    FirebaseFirestore.instance.collection('audio_guides').where('userId', isEqualTo: user.uid).snapshots().listen(
      (s) => updateResults('a_id', s.docs),
    );

    _ticketsStream = controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _ticketsStream == null) {
      return Scaffold(
        appBar: AppBar(title: Text('tickets_title'.tr())),
        body: Center(child: Text('tickets_login_required'.tr())),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('tickets_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _ticketsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allDocs = snapshot.data ?? [];
          if (allDocs.isEmpty) {
            return _buildEmptyState(Icons.confirmation_number_outlined, 'tickets_empty'.tr());
          }

          final allItems = List<DocumentSnapshot>.from(allDocs);
          
          DateTime getSortDate(DocumentSnapshot doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['visitDateTimestamp'] != null) return (data['visitDateTimestamp'] as Timestamp).toDate();
            
            final dateStr = data['visitDate'] as String?;
            if (dateStr != null) {
              try {
                final parts = dateStr.split('/');
                if (parts.length == 3) {
                  return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                }
              } catch (_) {}
            }
            
            final ts = data['timestamp'] as Timestamp? ?? data['purchaseDate'] as Timestamp?;
            return ts?.toDate() ?? DateTime(2000);
          }

          allItems.sort((a, b) => getSortDate(a).compareTo(getSortDate(b)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final doc = allItems[index];
              final data = doc.data() as Map<String, dynamic>;
              final isAudio = doc.reference.path.contains('audio_guides');
              return _TicketCard(data: data, docId: doc.id, isAudio: isAudio);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4))),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isAudio;

  const _TicketCard({required this.data, required this.docId, this.isAudio = false});

  bool _canChangeDate(String? visitDateStr, Timestamp? visitTimestamp) {
    if (isAudio) return false;
    DateTime? visitDate;
    
    if (visitTimestamp != null) {
      visitDate = visitTimestamp.toDate();
    } else if (visitDateStr != null) {
      // Intentar parsear el texto "dd/MM/yyyy" de las entradas antiguas
      try {
        final parts = visitDateStr.split('/');
        if (parts.length == 3) {
          visitDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (e) {
        return false;
      }
    }
    
    if (visitDate == null) return false;
    final now = DateTime.now();
    // Permitir si faltan más de 24 horas
    return visitDate.difference(now).inHours >= 24;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visitDateStr = data['visitDate'] as String? ?? '';
    final visitTimestamp = data['visitDateTimestamp'] as Timestamp?;
    final ticketCode = data['ticketId'] as String? ?? docId;
    final canChange = _canChangeDate(visitDateStr, visitTimestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(isAudio ? Icons.headset_mic : Icons.confirmation_number, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAudio ? 'Audio-guía (${data['quantity'] ?? 1})' : 'tickets_digital'.tr(args: [data['visitorName'] ?? '']), 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  )
                ),
                _buildStatusBadge(visitDateStr, visitTimestamp),
              ],
            ),
            const Divider(height: 32),
            _infoRow(context, Icons.calendar_today, 'tickets_visit_date'.tr(args: [visitDateStr])),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: ticketCode, size: 160, version: QrVersions.auto),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Share.share('tickets_share_msg'.tr(args: [visitDateStr, ticketCode])),
                    icon: const Icon(Icons.share, size: 18),
                    label: Text('tickets_share'.tr()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (canChange) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDatePicker(context),
                      icon: const Icon(Icons.edit_calendar, size: 18),
                      label: Text('tickets_change_date'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!canChange && visitTimestamp != null && !isAudio)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'tickets_error_24h'.tr(),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final newDateStr = DateFormat('dd/MM/yyyy').format(picked);
      await FirebaseFirestore.instance.collection('tickets').doc(docId).update({
        'visitDate': newDateStr,
        'visitDateTimestamp': Timestamp.fromDate(picked),
      });
    }
  }

  Widget _buildStatusBadge(String? visitDateStr, Timestamp? visitTimestamp) {
    final status = data['status'] as String? ?? 'active';
    if (status == 'used') return _statusChip('tickets_status_used'.tr(), Colors.grey);
    
    // Calcular si está caducada
    DateTime? visitDate;
    if (visitTimestamp != null) {
      visitDate = visitTimestamp.toDate();
    } else if (visitDateStr != null) {
      try {
        final parts = visitDateStr.split('/');
        if (parts.length == 3) {
          visitDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }

    if (visitDate != null) {
      final now = DateTime.now();
      final endOfVisitDay = DateTime(visitDate.year, visitDate.month, visitDate.day, 23, 59, 59);
      if (now.isAfter(endOfVisitDay)) {
        return _statusChip('tickets_status_expired'.tr(), Colors.redAccent);
      }
    }

    return _statusChip('tickets_status_active'.tr(), Colors.green);
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
    ],
  );
}
