import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

enum PrintStatus { pendiente, enCura, imprimiendo, listo }

class PrintRequest {
  final String id;
  final String catalogItemId;
  final String pieceName; // 🏺 Unificado
  final String itemImageUrl;
  final String stlUrl;
  final String userId;
  final String userEmail;
  final String? orderId; // 🆔 Añadido para seguimiento
  final PrintStatus status;
  final DateTime timestamp;
  final String? notes;

  PrintRequest({
    required this.id,
    required this.catalogItemId,
    required this.pieceName,
    required this.itemImageUrl,
    required this.stlUrl,
    required this.userId,
    required this.userEmail,
    this.orderId,
    required this.status,
    required this.timestamp,
    this.notes,
  });

  factory PrintRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrintRequest(
      id: doc.id,
      catalogItemId: data['catalogItemId'] ?? '',
      // 🕵️‍♂️ BÚSQUEDA INTELIGENTE: itemName o pieceName
      pieceName: data['pieceName'] ?? data['itemName'] ?? 'Objeto desconocido',
      itemImageUrl: data['itemImageUrl'] ?? '',
      stlUrl: data['stlUrl'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      orderId: data['orderId'],
      status: PrintStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pendiente'),
        orElse: () => PrintStatus.pendiente,
      ),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'catalogItemId': catalogItemId,
      'pieceName': pieceName,
      'itemImageUrl': itemImageUrl,
      'stlUrl': stlUrl,
      'userId': userId,
      'userEmail': userEmail,
      'orderId': orderId,
      'status': status.name,
      'timestamp': FieldValue.serverTimestamp(),
      'notes': notes,
    };
  }
}

class ShopState {
  final List<PrintRequest> myRequests;
  final List<PrintRequest> allRequests; // Para admins
  final bool isLoading;
  final String? error;

  ShopState({
    this.myRequests = const [],
    this.allRequests = const [],
    this.isLoading = false,
    this.error,
  });

  ShopState copyWith({
    List<PrintRequest>? myRequests,
    List<PrintRequest>? allRequests,
    bool? isLoading,
    String? error,
  }) {
    return ShopState(
      myRequests: myRequests ?? this.myRequests,
      allRequests: allRequests ?? this.allRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ShopNotifier() : super(ShopState()) {
    _initRequests();
  }

  void _initRequests() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Escuchar pedidos del usuario actual
    _firestore
        .collection('print_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final requests = snapshot.docs
                .map((doc) => PrintRequest.fromFirestore(doc))
                .toList();
            state = state.copyWith(myRequests: requests);
          },
          onError: (error) {
            debugPrint('🚨 Error en Stream de myRequests (Usuario): $error');
          },
        );

    // Escuchar todos los pedidos (Solo si es admin)
    final adminEmailsStr = dotenv.env['ADMIN_EMAIL'] ?? '';
    final adminEmailsList = adminEmailsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (user.email != null && adminEmailsList.contains(user.email)) {
      _firestore
          .collection('print_requests')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final requests = snapshot.docs
                  .map((doc) => PrintRequest.fromFirestore(doc))
                  .toList();
              state = state.copyWith(allRequests: requests);
            },
            onError: (error) {
              debugPrint(
                '🚨 Error en Stream de allRequests (3D Prints): $error',
              );
            },
          );
    }
  }

  Future<bool> createRequest({
    required String itemId,
    required String pieceName,
    required String imageUrl,
    required String stlUrl,
    String? orderId,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      state = state.copyWith(isLoading: true);

      final request = PrintRequest(
        id: '', // Firestore genera el ID
        catalogItemId: itemId,
        pieceName: pieceName,
        itemImageUrl: imageUrl,
        stlUrl: stlUrl,
        userId: user.uid,
        userEmail: user.email ?? 'Anónimo',
        orderId: orderId,
        status: PrintStatus.pendiente,
        timestamp: DateTime.now(),
        notes: notes,
      );

      await _firestore.collection('print_requests').add(request.toFirestore());

      state = state.copyWith(isLoading: false);

      FirebaseAnalytics.instance.logEvent(
        name: 'add_to_cart',
        parameters: {'item_id': itemId, 'item_name': pieceName},
      );

      return true;
    } catch (e) {
      FirebaseAnalytics.instance.logEvent(
        name: 'ecommerce_error',
        parameters: {'error_desc': e.toString()},
      );
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> updateStatus(String requestId, PrintStatus status) async {
    try {
      await _firestore.collection('print_requests').doc(requestId).update({
        'status': status.name,
      });
    } catch (e) {
      debugPrint('Error actualizando estado: $e');
    }
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  return ShopNotifier();
});
