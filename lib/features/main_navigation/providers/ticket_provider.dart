import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final data = doc.data() as Map<String, dynamic>;
    return DigitalTicket(
      id: doc.id,
      ticketId: data['ticketId'] ?? '',
      visitorName: data['visitorName'] ?? 'Anónimo',
      visitorEmail: data['visitorEmail'] ?? '',
      visitDate: data['visitDate'] ?? '',
      purchaseDate: data['purchaseDate'] != null
          ? (data['purchaseDate'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

final ticketsStreamProvider = StreamProvider<List<DigitalTicket>>((ref) {
  return FirebaseFirestore.instance
      .collection('tickets')
      .orderBy('purchaseDate', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => DigitalTicket.fromFirestore(doc))
            .toList(),
      );
});
