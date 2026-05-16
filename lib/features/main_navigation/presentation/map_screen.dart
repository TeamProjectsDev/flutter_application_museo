import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/catalog_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color bgColor = isDark ? const Color(0xFF080E26) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color iconColor = isDark ? Colors.blueAccent : theme.colorScheme.primary;
    
    // Obtener estado del catálogo para calcular ocupación de salas
    final catalogState = ref.watch(catalogProvider);
    final items = catalogState.items;

    if (context.locale.languageCode.isEmpty) {
      return Scaffold(backgroundColor: bgColor, body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'map_museum_title'.tr(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: iconColor),
            onPressed: () => _showMuseumInfo(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: isDark 
              ? [const Color(0xFF1A237E).withValues(alpha: 0.2), const Color(0xFF080E26)]
              : [Colors.white, const Color(0xFFF5F7FA)],
          ),
        ),
        child: InteractiveViewer(
          maxScale: 4.0,
          minScale: 1.0,
          boundaryMargin: const EdgeInsets.all(100),
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 1000,
                height: 1000,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(),
                        child: Image.asset(
                          'assets/images/map_premium.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.map_outlined, size: 100, color: iconColor.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                    _buildPin(context, items, x: 662, y: 607, roomKey: 'room_paleontology', color: Colors.amber, icon: Icons.pest_control_rodent_outlined),
                    _buildPin(context, items, x: 700, y: 420, roomKey: 'room_zoology', color: Colors.greenAccent, icon: Icons.pets),
                    _buildPin(context, items, x: 662, y: 170, roomKey: 'room_instruments', color: Colors.orangeAccent, icon: Icons.audiotrack),
                    _buildPin(context, items, x: 550, y: 520, roomKey: 'room_geology', color: Colors.blueAccent, icon: Icons.diamond),
                    _buildPin(context, items, x: 483, y: 320, roomKey: 'room_dark_camera', color: Colors.purpleAccent, icon: Icons.camera_rear),
                    _buildPin(context, items, x: 465, y: 420, roomKey: 'room_anatomy', color: Colors.redAccent, icon: Icons.accessibility_new),
                    _buildPin(context, items, x: 380, y: 640, roomKey: 'room_physics', color: Colors.cyanAccent, icon: Icons.science),
                    _buildPin(context, items, x: 320, y: 840, roomKey: 'room_storage', color: Colors.grey, icon: Icons.inventory_2_outlined),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPin(BuildContext context, List<CatalogItem> items, {
    required double x, 
    required double y, 
    required String roomKey, 
    required Color color,
    required IconData icon,
  }) {
    // Contar items en esta sala con seguridad contra nulos
    final int count = items.where((i) => i.room == roomKey).length;
    final bool isEmpty = count == 0;
    final Color pinColor = isEmpty ? Colors.grey.shade400 : color;

    return Positioned(
      left: x - 60,
      top: y - 60,
      child: GestureDetector(
        onTap: () => _showRoomDetails(context, roomKey.tr(), '${roomKey}_desc'.tr(), pinColor, roomKey, count),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEmpty)
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: pinColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: pinColor,
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: pinColor,
                  child: Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxWidth: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: isEmpty ? 0.4 : 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pinColor.withValues(alpha: 0.5), width: 2),
              ),
              child: Text(
                roomKey.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isEmpty ? 0.6 : 1.0), 
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context, String title, String info, Color color, String roomKey, int itemCount) {
    final bool isEmpty = itemCount == 0;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color currentBgColor = isDark ? const Color(0xFF080E26) : Colors.white;
    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color descColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: currentBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.location_on, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: titleColor)),
                      Text('PLANTA PRINCIPAL', style: TextStyle(fontSize: 10, color: isDark ? Colors.grey : Colors.grey[600], fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(info, style: TextStyle(fontSize: 15, color: descColor, height: 1.6)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isEmpty ? null : () {
                  Navigator.pop(context);
                  context.go('/collection?room=$roomKey');
                },
                icon: Icon(isEmpty ? Icons.lock_outline : Icons.explore_outlined),
                label: Text(
                  isEmpty 
                    ? 'PRÓXIMAMENTE'.toUpperCase()
                    : 'map_explore_objects'.tr().toUpperCase(), 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEmpty ? Colors.grey : color, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
              ),
            ),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Text(
                    'Esta sala no dispone de contenido digital todavía.',
                    style: TextStyle(fontSize: 12, color: descColor.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMuseumInfo(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF080E26) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.museum_outlined, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text('map_museum_title'.tr(), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18)),
          ],
        ),
        content: Text('map_museum_desc'.tr(), style: TextStyle(color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.7), height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('map_close'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
