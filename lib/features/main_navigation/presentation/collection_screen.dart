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

    // Guarda de traducción: Evitamos mostrar Keys crudas si el sistema aún está cargando
    if (context.locale.languageCode.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Lógica de filtrado preservada: 3D se filtra por sala, 360 siempre muestra todo
    var pieces3D = widget.filterRoom == null ? catalogState.pieces3D : catalogState.pieces3D.where((i) => i.room == widget.filterRoom).toList();
    var environments360 = catalogState.environments360; // Mostramos todos los 360 siempre

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
                  _buildGridGallery(context, collectionState, favoritesState, favoriteItems, null), // null significa "determinar por item"
                ],
              ),
      ),
    );
  }

  Widget _buildGridGallery(BuildContext context, CollectionState state, Set<String> favorites, List<CatalogItem> items, bool? is3D) {
    if (items.isEmpty) return Center(child: Text((is3D ?? true) ? 'collection_no_3d'.tr() : 'collection_no_360'.tr()));

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Una sola columna para mejor visibilidad en móvil
        mainAxisSpacing: 16,
        crossAxisSpacing: 0,
        childAspectRatio: 8.5, // Equilibrio perfecto entre compacidad y legibilidad
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isTester = int.tryParse(dotenv.env['TESTER'] ?? '0') == 1;
        final bool isVisited = state.unlockedItems.contains(item.id) || isTester;
        final bool isFav = favorites.contains(item.id);
        final bool isReally3D = is3D ?? item.fileName.toLowerCase().endsWith('.glb');
        return _buildArtifactCard(context, item, isVisited, isFav, isReally3D);
      },
    );
  }

  Widget _buildArtifactCard(BuildContext context, CatalogItem item, bool isVisited, bool isFav, bool isReally3D) {
    final theme = Theme.of(context);
    return InkWell(
      // Ahora todas las piezas son clicables por defecto
      onTap: () => context.push(isReally3D ? '/3d?model=${item.fileName}&room=${item.room}' : '/vr_explore?file=${item.fileName}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.displayMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVisited)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Colors.green, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'tickets_status_visited'.tr().toUpperCase(),
                                style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.room.tr(), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                      Row(
                        children: [
                          if (isReally3D)
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
    context.push(
      Uri(
        path: '/shop',
        queryParameters: {
          'id': item.id,
          'name': item.name,
          'stl': item.url,
        },
      ).toString(),
    );
  }
}
