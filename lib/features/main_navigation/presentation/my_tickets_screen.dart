import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text('tickets_title'.tr())),
        body: Center(child: Text('tickets_login_required'.tr())),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'tickets_title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5),
              Theme.of(context).brightness == Brightness.dark ? const Color(0xFF000814) : const Color(0xFFE0E0E0),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tickets')
              .where('userId', isEqualTo: uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 72,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'tickets_empty'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _TicketCard(data: data, docId: docs[index].id);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _TicketCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Visitante';
    final email = data['email'] as String? ?? '';
    final visitDate = data['visitDate'] as String? ?? 'Sin fecha';
    final ticketCode = data['ticketCode'] as String? ?? docId;
    final timestamp = data['timestamp'] as Timestamp?;
    final purchaseDate = timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
        : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'tickets_digital'.tr(args: [name]),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Info
            _infoRow(
              context,
              Icons.calendar_today,
              'tickets_visit_date'.tr(args: [visitDate]),
            ),
            _infoRow(context, Icons.email_outlined, email),
            _infoRow(
              context,
              Icons.receipt_long,
              'tickets_purchase_date'.tr(args: [purchaseDate]),
            ),
            const SizedBox(height: 16),

            // QR Code centrado
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: ticketCode,
                  version: QrVersions.auto,
                  size: 180,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                ticketCode,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Botón compartir
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Share.share(
                  'tickets_share_msg'.tr(args: [visitDate, ticketCode]),
                ),
                icon: const Icon(Icons.share, size: 18),
                label: Text('tickets_share'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber,
                  side: const BorderSide(color: Colors.amber),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
