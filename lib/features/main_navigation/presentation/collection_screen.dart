import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/collection_provider.dart';
import '../providers/catalog_provider.dart';

class CollectionScreen extends ConsumerWidget {
  final String? filterRoom;
  const CollectionScreen({super.key, this.filterRoom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Forzar reconstrucción por idioma

    final collectionState = ref.watch(collectionProvider);
    final catalogState = ref.watch(catalogProvider);

    // Filtrar ítems por sala si hay filtro
    final pieces3D = filterRoom == null
        ? catalogState.pieces3D
        : catalogState.pieces3D.where((i) => i.room == filterRoom).toList();

    final environments360 = filterRoom == null
        ? catalogState.environments360
        : catalogState.environments360
              .where((i) => i.room == filterRoom)
              .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('collection_gallery'.tr()),
          bottom: TabBar(
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(
                icon: Icon(Icons.view_in_ar),
                text: 'collection_3d_pieces'.tr(),
              ),
              Tab(icon: Icon(Icons.panorama), text: 'collection_360_envs'.tr()),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(catalogProvider.notifier).fetchCatalog(),
            ),
          ],
        ),
        body: catalogState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _build3DGallery(context, collectionState, pieces3D),
                  _build360Gallery(context, collectionState, environments360),
                ],
              ),
      ),
    );
  }

  Widget _build3DGallery(
    BuildContext context,
    CollectionState state,
    List<CatalogItem> items,
  ) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay piezas 3D disponibles.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;
        final bool isUnlocked =
            state.unlockedItems.contains(item.id) || isTester;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isUnlocked ? 4 : 1,
          color: isUnlocked ? Colors.white : Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              leading: Icon(
                isUnlocked ? Icons.view_in_ar : Icons.lock,
                color: isUnlocked ? Colors.deepPurple : Colors.grey,
                size: 32,
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  color: isUnlocked ? Colors.black : Colors.grey[600],
                  fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                isUnlocked ? item.description : 'collection_scan_to_view'.tr(),
              ),
              trailing: isUnlocked
                  ? OutlinedButton.icon(
                      onPressed: () {
                        final baseUrl = dotenv.env['GITHUB_RAW_URL'] ?? '';
                        final stlUrl = '$baseUrl/${item.fileName}';
                        context.push(
                          Uri(
                            path: '/shop',
                            queryParameters: {
                              'id': item.id,
                              'name': item.name,
                              'img':
                                  'https://picsum.photos/seed/${item.id}/200',
                              'stl': stlUrl,
                            },
                          ).toString(),
                        );
                      },
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text(
                        'Pedir 3D',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        side: const BorderSide(color: Colors.deepPurple),
                      ),
                    )
                  : const Icon(Icons.lock_outline, color: Colors.grey),
              onTap: isUnlocked
                  ? () => context.push('/3d?model=${item.fileName}')
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _build360Gallery(
    BuildContext context,
    CollectionState state,
    List<CatalogItem> items,
  ) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay entornos 360 disponibles.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;
        final bool isUnlocked =
            state.unlockedItems.contains(item.id) || isTester;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isUnlocked ? 4 : 1,
          color: isUnlocked ? null : Colors.grey[100],
          child: ListTile(
            leading: Icon(
              isUnlocked ? Icons.panorama : Icons.lock,
              color: isUnlocked ? Colors.deepPurple : Colors.grey,
            ),
            title: Text(
              item.name,
              style: TextStyle(
                color: isUnlocked ? Colors.black : Colors.grey[600],
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              isUnlocked ? item.description : 'Contenido bloqueado',
            ),
            trailing: isUnlocked
                ? const Icon(Icons.arrow_forward_ios, size: 16)
                : null,
            onTap: isUnlocked
                ? () => context.push('/vr_explore?file=${item.fileName}')
                : null,
          ),
        );
      },
    );
  }
}
