import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Clasificación automática por sala según palabras clave
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

  CatalogState({this.items = const [], this.isLoading = false, this.error});

  List<CatalogItem> get pieces3D =>
      items.where((i) => i.type == CatalogItemType.piece3D).toList();
  List<CatalogItem> get environments360 =>
      items.where((i) => i.type == CatalogItemType.environment360).toList();
}

class CatalogNotifier extends StateNotifier<CatalogState> {
  final Dio _dio = Dio();

  /// URL base de R2 (null si no está configurado → usa GitHub)
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
      state = CatalogState(items: [], isLoading: false, error: e.toString());
    }
  }

  /// Lee manifest.json del bucket R2 para construir el catálogo
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
        state = CatalogState(items: items, isLoading: false);
      } else {
        // Si no existe el manifest, hacemos fallback a GitHub
        debugPrint(
          '[Catalog] manifest.json no encontrado (${response.statusCode}) — fallback a GitHub',
        );
        await _fetchFromGithub();
      }
    } catch (e) {
      debugPrint('[Catalog] Error R2: $e — fallback a GitHub');
      await _fetchFromGithub();
    }
  }

  /// Consulta la API de GitHub para listar archivos reconocidos (.glb / .jpg / .png)
  Future<void> _fetchFromGithub() async {
    debugPrint('[Catalog] Fuente: GitHub API → $_githubApiUrl');
    final response = await _dio.get(_githubApiUrl);
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      final items = data
          .map((e) => CatalogItem.fromGithub(e as Map<String, dynamic>))
          .where((item) => item.type != CatalogItemType.unknown)
          .toList();
      state = CatalogState(items: items, isLoading: false);
    } else {
      state = CatalogState(
        items: [],
        isLoading: false,
        error: 'Error al cargar catálogo: ${response.statusCode}',
      );
    }
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((
  ref,
) {
  return CatalogNotifier();
});
