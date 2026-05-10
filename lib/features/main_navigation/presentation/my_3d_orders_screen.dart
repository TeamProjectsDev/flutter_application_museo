import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class My3DOrdersScreen extends StatefulWidget {
  const My3DOrdersScreen({super.key});

  @override
  State<My3DOrdersScreen> createState() => _My3DOrdersScreenState();
}

class _My3DOrdersScreenState extends State<My3DOrdersScreen> {
  Stream<List<DocumentSnapshot>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logEvent(name: 'view_3d_orders');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ordersStream = FirebaseFirestore.instance
          .collection('print_requests')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .map((s) => s.docs)
          .asBroadcastStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile_3d_orders'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(Icons.print_outlined, 'No tienes pedidos 3D aún');
          }

          final sortedDocs = List<DocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final tsA = dataA['timestamp'] as Timestamp? ?? dataA['purchaseDate'] as Timestamp?;
            final tsB = dataB['timestamp'] as Timestamp? ?? dataB['purchaseDate'] as Timestamp?;
            
            if (tsA == null && tsB == null) return 0;
            if (tsA == null) return 1;
            if (tsB == null) return -1;
            
            return tsB.compareTo(tsA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final data = sortedDocs[index].data() as Map<String, dynamic>;
              return _PrintRequestCard(data: data);
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

class _PrintRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PrintRequestCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusStr = data['status'] as String? ?? 'pendiente';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.print, color: theme.colorScheme.primary),
        ),
        title: Text(data['pieceName'] ?? data['itemName'] ?? 'Pedido 3D', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('ID: ${data['orderId'] ?? '?'}'),
        trailing: _statusChip(statusStr, theme),
      ),
    );
  }

  Widget _statusChip(String status, ThemeData theme) {
    Color color = Colors.orange;
    if (status == 'listo') color = Colors.green;
    if (status == 'imprimiendo' || status == 'enCura') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
