import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/collection_provider.dart';
import '../providers/catalog_provider.dart';
import '../providers/favorites_provider.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  final String? filterRoom;
  const CollectionScreen({super.key, this.filterRoom});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collectionState = ref.watch(collectionProvider);
    final catalogState = ref.watch(catalogProvider);
    final favoritesState = ref.watch(favoritesProvider);

    // Filtrar por sala si hay filtro desde el mapa
    var pieces3D = widget.filterRoom == null
        ? catalogState.pieces3D
        : catalogState.pieces3D
              .where((i) => i.room == widget.filterRoom)
              .toList();

    var environments360 = widget.filterRoom == null
        ? catalogState.environments360
        : catalogState.environments360
              .where((i) => i.room == widget.filterRoom)
              .toList();

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pieces3D = pieces3D
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                i.room.toLowerCase().contains(q),
          )
          .toList();
      environments360 = environments360
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                i.room.toLowerCase().contains(q),
          )
          .toList();
    }

    final favoriteItems = catalogState.items
        .where((i) => favoritesState.contains(i.id))
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('collection_gallery'.tr()),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                // Buscador
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'collection_search_hint'.tr(),
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white54,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white12,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Tabs
                TabBar(
                  indicatorColor: Colors.deepPurple,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.view_in_ar),
                      text: 'collection_3d_pieces'.tr(),
                    ),
                    Tab(
                      icon: const Icon(Icons.panorama),
                      text: 'collection_360_envs'.tr(),
                    ),
                    const Tab(icon: Icon(Icons.favorite), text: 'Favoritos'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            if (catalogState.isFromCache)
              Tooltip(
                message: 'collection_offline_tooltip'.tr(),
                child: const Icon(Icons.wifi_off, color: Colors.orange),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(catalogProvider.notifier).fetchCatalog(),
              tooltip: 'collection_refresh'.tr(),
            ),
          ],
        ),
        body: catalogState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildGallery(
                    context,
                    collectionState,
                    favoritesState,
                    pieces3D,
                    is3D: true,
                  ),
                  _buildGallery(
                    context,
                    collectionState,
                    favoritesState,
                    environments360,
                    is3D: false,
                  ),
                  _buildFavoritesTab(context, collectionState, favoriteItems),
                ],
              ),
      ),
    );
  }

  Widget _buildGallery(
    BuildContext context,
    CollectionState state,
    Set<String> favorites,
    List<CatalogItem> items, {
    required bool is3D,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text(is3D ? 'collection_no_3d'.tr() : 'collection_no_360'.tr()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;
        final bool isUnlocked =
            state.unlockedItems.contains(item.id) || isTester;
        final bool isFav = favorites.contains(item.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isUnlocked ? 4 : 1,
          color: isUnlocked ? null : Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              isUnlocked
                  ? (is3D ? Icons.view_in_ar : Icons.panorama)
                  : Icons.lock,
              color: isUnlocked ? Colors.deepPurple : Colors.grey,
              size: 32,
            ),
            title: Text(
              item.name,
              style: TextStyle(
                color: isUnlocked ? null : Colors.grey[600],
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              isUnlocked ? item.description : 'collection_scan_to_view'.tr(),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón Favorito
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.redAccent : Colors.grey,
                  ),
                  tooltip: isFav
                      ? 'collection_fav_remove'.tr()
                      : 'collection_fav_add'.tr(),
                  onPressed: () =>
                      ref.read(favoritesProvider.notifier).toggle(item.id),
                ),
                // Botón Compartir
                if (isUnlocked)
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.deepPurple),
                    tooltip: 'collection_share'.tr(),
                    onPressed: () => Share.share(
                      'collection_share_msg'.tr(args: [item.name]),
                    ),
                  ),
                // Botón Imprimir 3D
                if (is3D && isUnlocked)
                  OutlinedButton.icon(
                    onPressed: () {
                      final baseUrl = dotenv.env['R2_PUBLIC_URL'] ?? '';
                      context.push(
                        Uri(
                          path: '/shop',
                          queryParameters: {
                            'id': item.id,
                            'name': item.name,
                            'img': 'https://picsum.photos/seed/${item.id}/200',
                            'stl': '$baseUrl/${item.fileName}',
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
                  ),
                if (!isUnlocked)
                  const Icon(Icons.lock_outline, color: Colors.grey),
              ],
            ),
            onTap: isUnlocked
                ? () => context.push(
                    is3D
                        ? '/3d?model=${item.fileName}'
                        : '/vr_explore?file=${item.fileName}',
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    CollectionState state,
    List<CatalogItem> items,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'collection_no_favorites'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return _buildGallery(
      context,
      state,
      items.map((i) => i.id).toSet(),
      items,
      is3D: items.first.type == CatalogItemType.piece3D,
    );
  }
}
