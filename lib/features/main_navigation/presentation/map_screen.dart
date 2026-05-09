import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

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

    // Colores dinámicos
    final Color bgColor = isDark ? const Color(0xFF080E26) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color iconColor = isDark ? Colors.blueAccent : theme.colorScheme.primary;

    // Guarda de seguridad para traducciones
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
            radius: 1.5,
            colors: isDark 
              ? [const Color(0xFF0F1730), const Color(0xFF080E26)]
              : [Colors.white, const Color(0xFFF0F2F5)],
          ),
        ),
        child: InteractiveViewer(
          maxScale: 3.0,
          minScale: 1.0,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1000,
                  height: 600,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Imagen del Mapa Base
                      Positioned.fill(
                        child: Image.asset(
                          isDark ? 'assets/images/museum_map.png' : 'assets/images/museum_map_light.png',
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/museum_map.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),

                      // Pines con coordenadas fijas (Búnker)
                      _buildPin(context, x: 220, y: 260, roomKey: 'room_paleontology', color: Colors.amber, icon: Icons.pest_control_rodent_outlined),
                      _buildPin(context, x: 480, y: 180, roomKey: 'room_zoology', color: Colors.greenAccent, icon: Icons.pets),
                      _buildPin(context, x: 820, y: 190, roomKey: 'room_archaeology', color: Colors.orangeAccent, icon: Icons.account_balance),
                      _buildPin(context, x: 530, y: 460, roomKey: 'room_anatomy', color: Colors.redAccent, icon: Icons.accessibility_new),
                      _buildPin(context, x: 830, y: 420, roomKey: 'room_physics', color: Colors.cyanAccent, icon: Icons.science),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPin(BuildContext context, {
    required double x, 
    required double y, 
    required String roomKey, 
    required Color color,
    required IconData icon,
  }) {
    return Positioned(
      left: x - 60, // Ajustado para centrar el nuevo ancho de 120
      top: y - 60,
      child: GestureDetector(
        onTap: () => _showRoomDetails(context, roomKey.tr(), '${roomKey}_desc'.tr(), color, roomKey),
        child: SizedBox(
          width: 120, // Aumentado de 100 a 120 para palabras largas
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: color,
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                ),
                child: Text(
                  roomKey.tr(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 11, // Bajado de 12 a 11 para asegurar una sola línea
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1, // Forzamos una sola línea
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomDetails(BuildContext context, String title, String info, Color color, String roomKey) {
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
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/collection?room=$roomKey');
                },
                icon: const Icon(Icons.explore_outlined),
                label: Text('map_explore_objects'.tr().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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
