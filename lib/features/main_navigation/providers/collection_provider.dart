import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../core/services/widget_service.dart';

class CollectionState {
  final Set<String> unlockedItems;
  final bool isLoading;
  final String? error;

  CollectionState({
    this.unlockedItems = const {},
    this.isLoading = false,
    this.error,
  });

  CollectionState copyWith({
    Set<String>? unlockedItems,
    bool? isLoading,
    String? error,
  }) {
    return CollectionState(
      unlockedItems: unlockedItems ?? this.unlockedItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CollectionNotifier extends StateNotifier<CollectionState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userId;
  StreamSubscription? _subscription;

  CollectionNotifier(this._userId)
    : super(CollectionState(isLoading: _userId != null)) {
    if (_userId != null) {
      _listenToCollection();
    }
  }

  void _listenToCollection() {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              final List<dynamic> items = data['unlocked_items'] ?? [];
              state = state.copyWith(
                unlockedItems: items.cast<String>().toSet(),
                isLoading: false,
              );
            } else {
              state = state.copyWith(unlockedItems: {}, isLoading: false);
            }
          },
          onError: (e) {
            state = state.copyWith(error: e.toString(), isLoading: false);
          },
        );
  }

  Future<void> unlockItem(String itemId) async {
    if (_userId == null) return;

    try {
      await _firestore.collection('users').doc(_userId).set({
        'unlocked_items': FieldValue.arrayUnion([itemId]),
      }, SetOptions(merge: true));

      // Actualizamos el Widget de la Home Screen
      await WidgetService.updateHomeWidget(
        title: '¡Nuevo Hallazgo!',
        message: 'Has descubierto: $itemId',
        lastItem: itemId,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error al desbloquear: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final collectionProvider =
    StateNotifierProvider<CollectionNotifier, CollectionState>((ref) {
      final authState = ref.watch(authProvider);
      // Re-inicializamos el notifier cuando cambia el usuario (login/logout)
      // Nota: Firebase Auth uid es null si no está autenticado o es invitado (pero invitado tiene UID)
      // Preferimos manejarlo solo si isAuthenticated es true
      return CollectionNotifier(authState.userId);
    });
