import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
    final theme = Theme.of(context);
    final catalogState = ref.watch(catalogProvider);
    final collectionState = ref.watch(collectionProvider);
    final favoritesState = ref.watch(favoritesProvider);

    // Lógica de filtrado preservada
    var pieces3D = widget.filterRoom == null ? catalogState.pieces3D : catalogState.pieces3D.where((i) => i.room == widget.filterRoom).toList();
    var environments360 = widget.filterRoom == null ? catalogState.environments360 : catalogState.environments360.where((i) => i.room == widget.filterRoom).toList();

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      pieces3D = pieces3D.where((i) => i.name.toLowerCase().contains(q) || i.room.toLowerCase().contains(q)).toList();
      environments360 = environments360.where((i) => i.name.toLowerCase().contains(q) || i.room.toLowerCase().contains(q)).toList();
    }

    final favoriteItems = catalogState.items.where((i) => favoritesState.contains(i.id)).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('collection_gallery'.tr(), style: theme.textTheme.displayMedium?.copyWith(fontSize: 20)),
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: theme.colorScheme.primary, size: 28),
              onPressed: () => context.push('/settings'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(110),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'collection_search_hint'.tr(),
                      prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                TabBar(
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  tabs: [
                    Tab(text: '3D'.tr()),
                    Tab(text: '360'.tr()),
                    Tab(text: 'Favs'.tr()),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: catalogState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildGridGallery(context, collectionState, favoritesState, pieces3D, true),
                  _buildGridGallery(context, collectionState, favoritesState, environments360, false),
                  _buildGridGallery(context, collectionState, favoritesState, favoriteItems, true),
                ],
              ),
      ),
    );
  }

  Widget _buildGridGallery(BuildContext context, CollectionState state, Set<String> favorites, List<CatalogItem> items, bool is3D) {
    if (items.isEmpty) return Center(child: Text(is3D ? 'collection_no_3d'.tr() : 'collection_no_360'.tr()));

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 4.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;
        final bool isUnlocked = state.unlockedItems.contains(item.id) || isTester;
        final bool isFav = favorites.contains(item.id);

        return _buildArtifactCard(context, item, isUnlocked, isFav, is3D);
      },
    );
  }

  Widget _buildArtifactCard(BuildContext context, CatalogItem item, bool isUnlocked, bool isFav, bool is3D) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: isUnlocked ? () => context.push(is3D ? '/3d?model=${item.fileName}&room=${item.room}' : '/vr_explore?file=${item.fileName}') : null,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con overlay si está bloqueado
            // Parte superior eliminada por petición del usuario
            // Información de la pieza
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.displayMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.room.tr(), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                      Row(
                        children: [
                          if (isUnlocked && is3D)
                            GestureDetector(
                              onTap: () => _handle3DRequest(context, item),
                              child: Icon(Icons.print_outlined, size: 24, color: theme.colorScheme.primary),
                            ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ref.read(favoritesProvider.notifier).toggle(item.id),
                            child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.redAccent : theme.colorScheme.primary.withValues(alpha: 0.5), size: 24),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handle3DRequest(BuildContext context, CatalogItem item) {
    final baseUrl = dotenv.env['R2_PUBLIC_URL'] ?? '';
    context.push(
      Uri(
        path: '/shop',
        queryParameters: {
          'id': item.id,
          'name': item.name,
          'stl': '$baseUrl/${item.fileName}',
        },
      ).toString(),
    );
  }
}
