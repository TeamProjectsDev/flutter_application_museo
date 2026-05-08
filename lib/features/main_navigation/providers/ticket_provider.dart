import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class DigitalTicket {
  final String id;
  final String ticketId;
  final String visitorName;
  final String visitorEmail;
  final String visitDate;
  final DateTime purchaseDate;

  DigitalTicket({
    required this.id,
    required this.ticketId,
    required this.visitorName,
    required this.visitorEmail,
    required this.visitDate,
    required this.purchaseDate,
  });

  factory DigitalTicket.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return DigitalTicket(
        id: doc.id,
        ticketId: data['ticketId'] ?? 'N/A',
        visitorName: data['visitorName'] ?? 'Anónimo',
        visitorEmail: data['visitorEmail'] ?? 'Sin email',
        visitDate: data['visitDate'] ?? 'Pendiente',
        purchaseDate: data['purchaseDate'] != null
            ? (data['purchaseDate'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('🚨 Error parseando ticket ${doc.id}: $e');
      return DigitalTicket(
        id: doc.id,
        ticketId: 'ERROR',
        visitorName: 'Error de datos',
        visitorEmail: '',
        visitDate: '',
        purchaseDate: DateTime.now(),
      );
    }
  }
}



class Purchase {
  final String id;
  final String orderId;
  final String customerName;
  final String customerEmail;
  final String visitDate;
  final DateTime purchaseDate;
  final Map<String, dynamic> items;
  final String totalAmount;

  Purchase({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    required this.visitDate,
    required this.purchaseDate,
    required this.items,
    required this.totalAmount,
  });

  factory Purchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Purchase(
      id: doc.id,
      orderId: data['orderId'] ?? 'N/A',
      customerName: data['customerName'] ?? 'Anónimo',
      customerEmail: data['customerEmail'] ?? '',
      visitDate: data['visitDate'] ?? '',
      purchaseDate: data['purchaseDate'] != null
          ? (data['purchaseDate'] as Timestamp).toDate()
          : DateTime.now(),
      items: data['items'] ?? {},
      totalAmount: data['totalAmount'] ?? '0',
    );
  }
}

final purchasesStreamProvider = StreamProvider<List<Purchase>>((ref) {
  return FirebaseFirestore.instance
      .collection('tickets')
      .snapshots()
      .map(
        (snapshot) {
          final all = snapshot.docs.map((doc) => Purchase.fromFirestore(doc)).toList();
          // Filtrar y ordenar en memoria para evitar errores de índice en Firestore
          final filtered = all.where((p) {
            final data = snapshot.docs.firstWhere((d) => d.id == p.id).data();
            return data['type'] == 'order_master';
          }).toList();
          
          filtered.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
          return filtered;
        },
      );
});

final ticketsStreamProvider = StreamProvider<List<DigitalTicket>>((ref) {
  return FirebaseFirestore.instance
      .collection('tickets')
      .orderBy('purchaseDate', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data();
              // Mostrar si tiene ticketId y NO es un registro maestro de pedido
              return data['ticketId'] != null && data['type'] != 'order_master';
            })
            .map((doc) => DigitalTicket.fromFirestore(doc))
            .toList(),
      );
});
