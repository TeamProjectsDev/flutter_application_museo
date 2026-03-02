import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CatalogItemType { piece3D, environment360, unknown }

class CatalogItem {
  final String id;
  final String name;
  final String fileName;
  final String description;
  final CatalogItemType type;
  final String room; // Nueva propiedad para el mapa

  CatalogItem({
    required this.id,
    required this.name,
    required this.fileName,
    required this.description,
    required this.type,
    required this.room,
  });

  factory CatalogItem.fromGithub(Map<String, dynamic> json) {
    final String name = json['name'] as String;
    final String lowercaseName = name.toLowerCase();

    CatalogItemType type = CatalogItemType.unknown;
    if (lowercaseName.endsWith('.glb')) {
      type = CatalogItemType.piece3D;
    } else if (lowercaseName.endsWith('.jpg') ||
        lowercaseName.endsWith('.png')) {
      type = CatalogItemType.environment360;
    }

    // Clasificación por salas basada en palabras clave
    String room = 'General';
    if (lowercaseName.contains('mandibula') ||
        lowercaseName.contains('fosil') ||
        lowercaseName.contains('diente')) {
      room = 'Paleontología';
    } else if (lowercaseName.contains('animal') ||
        lowercaseName.contains('ave') ||
        lowercaseName.contains('insecto')) {
      room = 'Zoología';
    } else if (lowercaseName.contains('vasija') ||
        lowercaseName.contains('hacha') ||
        lowercaseName.contains('romano')) {
      room = 'Arqueología';
    } else if (lowercaseName.contains('auzoux') ||
        lowercaseName.contains('anatomia')) {
      room = 'Modelos Anatómicos';
    } else if (lowercaseName.contains('telescopio') ||
        lowercaseName.contains('fisica')) {
      room = 'Instrumentación';
    }

    // "mandibula hombre.glb" -> "Mandíbula Hombre"
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
  final String _repoUrl =
      'https://api.github.com/repos/alberto2005-coder/Museo/contents';

  CatalogNotifier() : super(CatalogState(isLoading: true)) {
    fetchCatalog();
  }

  Future<void> fetchCatalog() async {
    try {
      state = CatalogState(items: state.items, isLoading: true);

      final response = await _dio.get(_repoUrl);
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
          error: 'Error al cargar catálogo',
        );
      }
    } catch (e) {
      state = CatalogState(items: [], isLoading: false, error: e.toString());
    }
  }
}

final catalogProvider = StateNotifierProvider<CatalogNotifier, CatalogState>((
  ref,
) {
  return CatalogNotifier();
});
