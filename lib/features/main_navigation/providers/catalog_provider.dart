import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _cacheKey = 'cached_catalog_v3';

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

  static String buildCloudinaryUrl(String fileName) {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'ds0vozscv';
    final lower = fileName.toLowerCase();
    
    if (lower.endsWith('.glb') || lower.endsWith('.gltf')) {
      // Para modelos 3D usamos la ruta directa que acabamos de probar
      return 'https://res.cloudinary.com/$cloudName/image/upload/$fileName';
    } else {
      // Para fotos 360, añadimos optimización automática
      return 'https://res.cloudinary.com/$cloudName/image/upload/f_auto,q_auto/$fileName';
    }
  }

  String get url => buildCloudinaryUrl(fileName);

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

  /// Parsea un ítem desde el listado de archivos de Supabase
  /// Parsea un ítem desde el listado de archivos de Supabase
  factory CatalogItem.fromSupabase(
    Map<String, dynamic> json, [
    Map<String, dynamic>? metadata,
  ]) {
    final String fileName = json['name'] as String? ?? '';
    final String lower = fileName.toLowerCase();

    CatalogItemType type = CatalogItemType.unknown;
    if (lower.endsWith('.glb') || lower.endsWith('.gltf')) {
      type = CatalogItemType.piece3D;
    } else if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png')) {
      type = CatalogItemType.environment360;
    }

    // Buscar si hay metadatos específicos para este archivo
    final extra = metadata?[fileName] as Map<String, dynamic>?;

    // Si no hay metadatos, usamos valores por defecto limpios (sin inventar)
    final String prettyName = extra?['name'] ??
        fileName.split('.').first.replaceAll('_', ' ').replaceAll('-', ' ');

    return CatalogItem(
      id: fileName.split('.').first.replaceAll(' ', '_'),
      name: extra != null
          ? prettyName
          : (prettyName.isNotEmpty
              ? prettyName[0].toUpperCase() + prettyName.substring(1)
              : prettyName),
      fileName: fileName,
      description: extra?['description'] ??
          (type == CatalogItemType.piece3D
              ? 'Pieza pendiente de catalogación técnica.'
              : 'Entorno virtual 360'),
      type: type,
      room: extra?['room'] ?? 'map_general',
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

  CatalogNotifier() : super(CatalogState(isLoading: true)) {
    fetchCatalog();
  }

  Future<void> fetchCatalog() async {
    state = CatalogState(items: state.items, isLoading: true);
    try {
      // Cargar metadatos del inventario (local) - Fuente de verdad
      final metadata = await _loadMetadata();
      
      if (metadata.isEmpty) {
        await _loadFromCache();
        return;
      }

      // Construir los ítems basados en el catálogo local y Cloudinary
      final List<CatalogItem> items = [];
      
      metadata.forEach((fileName, data) {
        final Map<String, dynamic> itemData = data as Map<String, dynamic>;
        final String lower = fileName.toLowerCase();
        
        CatalogItemType type = CatalogItemType.unknown;
        if (lower.endsWith('.glb') || lower.endsWith('.gltf')) {
          type = CatalogItemType.piece3D;
        } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
          type = CatalogItemType.environment360;
        }

        if (type != CatalogItemType.unknown) {
          items.add(CatalogItem(
            id: fileName.split('.').first.replaceAll(' ', '_'),
            name: itemData['name'] ?? fileName,
            fileName: fileName,
            description: itemData['description'] ?? '',
            type: type,
            room: itemData['room'] ?? 'map_general',
          ));
        }
      });

      await _saveToCache(items);
      state = CatalogState(items: items, isLoading: false);
      debugPrint('[Catalog] Sincronizado con Cloudinary: ${items.length} ítems configurados.');
      
    } catch (e) {
      debugPrint('[Catalog] Error procesando catálogo: $e');
      await _loadFromCache();
    }
  }

  Future<Map<String, dynamic>> _loadMetadata() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'assets/data/inventory/catalog_metadata.json',
      );
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Catalog] No se pudo cargar catalog_metadata.json: $e');
      return {};
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
