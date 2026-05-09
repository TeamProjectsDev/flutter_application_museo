import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/museum_config.dart';

class ConfigState {
  final MuseumConfig? config;
  final bool isLoading;
  final String? error;

  ConfigState({this.config, this.isLoading = false, this.error});
}

class ConfigNotifier extends StateNotifier<ConfigState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;

  ConfigNotifier() : super(ConfigState(isLoading: true)) {
    _init();
  }

  void _init() {
    _subscription = _firestore
        .collection('museum_config')
        .doc('settings')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        state = ConfigState(config: MuseumConfig.fromFirestore(doc), isLoading: false);
      } else {
        // Si no existe, creamos uno por defecto
        _createDefaultConfig();
      }
    }, onError: (e) {
      state = ConfigState(error: e.toString(), isLoading: false);
    });
  }

  Future<void> _createDefaultConfig() async {
    final defaultConfig = MuseumConfig(
      maxDailyCapacity: 100,
      isGlobalOpen: true,
    );
    await _firestore
        .collection('museum_config')
        .doc('settings')
        .set(defaultConfig.toFirestore());
  }

  // --- Funciones para el Administrador ---

  Future<void> updateGlobalCapacity(int newCapacity) async {
    await _firestore
        .collection('museum_config')
        .doc('settings')
        .update({'max_daily_capacity': newCapacity});
  }

  Future<void> toggleGlobalOpen(bool isOpen) async {
    await _firestore
        .collection('museum_config')
        .doc('settings')
        .update({'is_global_open': isOpen});
  }

  Future<void> setDayOverride(String dateKey, DayConfig dayConfig) async {
    // dateKey formato: "YYYY-MM-DD"
    await _firestore.collection('museum_config').doc('settings').update({
      'calendar_overrides.$dateKey': dayConfig.toMap(),
    });
  }

  Future<void> removeDayOverride(String dateKey) async {
    await _firestore.collection('museum_config').doc('settings').update({
      'calendar_overrides.$dateKey': FieldValue.delete(),
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final configProvider = StateNotifierProvider<ConfigNotifier, ConfigState>((ref) {
  return ConfigNotifier();
});
