import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localFavKey = 'local_favorites';

/// Gestiona los favoritos del usuario. Para usuarios autenticados los guarda
/// en Firestore. Para invitados usa SharedPreferences localmente.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final data = doc.data();
        if (data != null && data['favorites'] is List) {
          state = Set<String>.from(data['favorites'] as List);
        }
      } catch (e) {
        debugPrint('[Favorites] Error al cargar desde Firestore: $e');
        await _loadLocal();
      }
    } else {
      await _loadLocal();
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_localFavKey) ?? [];
    state = Set<String>.from(list);
  }

  Future<void> toggle(String itemId) async {
    final updated = Set<String>.from(state);
    if (updated.contains(itemId)) {
      updated.remove(itemId);
    } else {
      updated.add(itemId);
    }
    state = updated;
    await _persist(updated);
  }

  bool isFavorite(String itemId) => state.contains(itemId);

  Future<void> _persist(Set<String> ids) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'favorites': ids.toList(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[Favorites] Error al guardar en Firestore: $e');
        await _saveLocal(ids);
      }
    } else {
      await _saveLocal(ids);
    }
  }

  Future<void> _saveLocal(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_localFavKey, ids.toList());
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);
