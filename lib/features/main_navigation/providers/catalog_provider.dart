import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cacheKey = 'cached_catalog_v1';

enum CatalogItemType { piece3D, environment360, unknown }

class CatalogItem {
  final String id;
  final String name;
  final String fileName;
  final String description;
  final CatalogItemType type;
  final String room;

  CatalogItem({
    required this.id,
    required this.name,
    required this.fileName,
    required this.description,
    required this.type,
    required this.room,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fileName': fileName,
    'description': description,
    'type': type.name,
    'room': room,
  };

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'unknown';
    final type = CatalogItemType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => CatalogItemType.unknown,
    );
    return CatalogItem(
      id: json['id'] as String,
      name: json['name'] as String,
      fileName: json['fileName'] as String,
      description: json['description'] as String? ?? '',
      type: type,
      room: json['room'] as String? ?? 'General',
    );
  }

  /// Parsea un ítem desde el manifest.json de Cloudflare R2
  factory CatalogItem.fromR2Manifest(Map<String, dynamic> json) {
    final String fileName = json['fileName'] as String? ?? '';
    final String lower = fileName.toLowerCase();

    CatalogItemType type = CatalogItemType.unknown;
    if (lower.endsWith('.glb') || lower.endsWith('.gltf')) {
      type = CatalogItemType.piece3D;
    } else if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png')) {
      type = CatalogItemType.environment360;
    }

    return CatalogItem(
      id: fileName.split('.').first.replaceAll(' ', '_'),
      name: json['name'] as String? ?? fileName.split('.').first,
      fileName: fileName,
      description: json['description'] as String? ?? '',
      type: type,
      room: json['room'] as String? ?? 'General',
    );
  }

  /// Parsea un ítem desde la respuesta de la API de GitHub
  factory CatalogItem.fromGithub(Map<String, dynamic> json) {
    final String name = json['name'] as String;
    final String lower = name.toLowerCase();

    CatalogItemType type = CatalogItemType.unknown;
    if (lower.endsWith('.glb')) {
      type = CatalogItemType.piece3D;
    } else if (lower.endsWith('.jpg') || lower.endsWith('.png')) {
      type = CatalogItemType.environment360;
    }

    String room = 'General';
    if (lower.contains('mandibula') ||
        lower.contains('fosil') ||
        lower.contains('diente')) {
      room = 'Paleontología';
    } else if (lower.contains('animal') ||
        lower.contains('ave') ||
        lower.contains('insecto')) {
      room = 'Zoología';
    } else if (lower.contains('vasija') ||
        lower.contains('hacha') ||
        lower.contains('romano')) {
      room = 'Arqueología';
    } else if (lower.contains('auzoux') || lower.contains('anatomia')) {
      room = 'Modelos Anatómicos';
    } else if (lower.contains('telescopio') || lower.contains('fisica')) {
      room = 'Instrumentación';
    }

    String prettyName = name.split('.').first;
    prettyName = prettyName.replaceAll('_', ' ').replaceAll('-', ' ');
    if (prettyName.isNotEmpty) {
      prettyName = prettyName[0].toUpperCase() + prettyName.substring(1);
    }

    return CatalogItem(
      id: name.split('.').first.replaceAll(' ', '_'),
      name: prettyName,
      fileName: name,
      description: type == CatalogItemType.piece3D
          ? 'Pieza de la sala $room'
          : 'Vista panorámica',
      type: type,
      room: room,
    );
  }
}

class CatalogState {
  final List<CatalogItem> items;
  final bool isLoading;
  final String? error;
  final bool isFromCache;

  CatalogState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isFromCache = false,
  });

  List<CatalogItem> get pieces3D =>
      items.where((i) => i.type == CatalogItemType.piece3D).toList();
  List<CatalogItem> get environments360 =>
      items.where((i) => i.type == CatalogItemType.environment360).toList();
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final Dio _dio = Dio();

  final String? _r2BaseUrl = (dotenv.env['R2_PUBLIC_URL'] ?? '').isNotEmpty
      ? dotenv.env['R2_PUBLIC_URL']
      : null;

  final String _githubApiUrl =
      'https://api.github.com/repos/alberto2005-coder/Museo/contents';

  CatalogNotifier() : super(CatalogState(isLoading: true)) {
    fetchCatalog();
  }

  Future<void> fetchCatalog() async {
    state = CatalogState(items: state.items, isLoading: true);
    try {
      if (_r2BaseUrl != null) {
        await _fetchFromR2();
      } else {
        await _fetchFromGithub();
      }
    } catch (e) {
      debugPrint('[Catalog] Error de red: $e — intentando caché local');
      await _loadFromCache();
    }
  }

  Future<void> _fetchFromR2() async {
    final manifestUrl = '$_r2BaseUrl/manifest.json';
    debugPrint('[Catalog] Fuente: R2 → $manifestUrl');
    try {
      final response = await _dio.get(manifestUrl);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final rawItems = data['items'] as List<dynamic>? ?? [];
        final items = rawItems
            .map((e) => CatalogItem.fromR2Manifest(e as Map<String, dynamic>))
            .where((item) => item.type != CatalogItemType.unknown)
            .toList();
        await _saveToCache(items);
        state = CatalogState(items: items, isLoading: false);
      } else {
        await _fetchFromGithub();
      }
    } catch (e) {
      debugPrint('[Catalog] Error R2: $e — fallback a GitHub');
      await _fetchFromGithub();
    }
  }

  Future<void> _fetchFromGithub() async {
    debugPrint('[Catalog] Fuente: GitHub API → $_githubApiUrl');
    try {
      final response = await _dio.get(_githubApiUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final items = data
            .map((e) => CatalogItem.fromGithub(e as Map<String, dynamic>))
            .where((item) => item.type != CatalogItemType.unknown)
            .toList();
        await _saveToCache(items);
        state = CatalogState(items: items, isLoading: false);
      } else {
        await _loadFromCache();
      }
    } catch (e) {
      debugPrint('[Catalog] Error GitHub: $e — cargando caché');
      await _loadFromCache();
    }
  }

  Future<void> _saveToCache(List<CatalogItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((i) => i.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      debugPrint(
        '[Catalog] Catálogo guardado en caché (${items.length} ítems)',
      );
    } catch (e) {
      debugPrint('[Catalog] Error al guardar caché: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        final items = jsonList
            .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
            .toList();
        debugPrint(
          '[Catalog] Catálogo cargado desde caché (${items.length} ítems)',
        );
        state = CatalogState(items: items, isLoading: false, isFromCache: true);
      } else {
        state = CatalogState(
          items: [],
          isLoading: false,
          error: 'Sin conexión y sin catálogo guardado.',
          isFromCache: true,
        );
      }
    } catch (e) {
      state = CatalogState(
        items: [],
        isLoading: false,
        error: 'Error al cargar catálogo: $e',
      );
    }
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((
  ref,
) {
  return CatalogNotifier();
});
