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

    // Colores y assets dinámicos según el tema
    final Color bgColor = isDark ? const Color(0xFF080E26) : Colors.white;
    final String mapAsset = isDark ? 'assets/images/museum_map.png' : 'assets/images/museum_map_light.png';
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color iconColor = isDark ? Colors.blueAccent : theme.colorScheme.primary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'map_museum_title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: iconColor),
            onPressed: () => _showMuseumInfo(context),
          ),
        ],
      ),
      body: Container(
        // Fondo dinámico según el tema
        color: bgColor, 
        child: LayoutBuilder(
          builder: (context, constraints) {
            // El canvas es un poco más grande que la pantalla para permitir zoom
            final canvasWidth = constraints.maxWidth > 800 ? constraints.maxWidth : 1200.0;
            final canvasHeight = canvasWidth * 0.55; 

            return InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.1,
              boundaryMargin: const EdgeInsets.all(500),
              child: Center(
                child: SizedBox(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Capa del Mapa (Fondo Dinámico)
                      Positioned.fill(
                        child: Image.asset(
                          mapAsset,
                          fit: BoxFit.fill,
                          // Si no encuentra la imagen de modo claro, muestra la oscura para que no de error crítico
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/museum_map.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),

                      // Sala I: Paleontología (Dinosaurios)
                      _buildAnimatedPin(
                        context,
                        x: canvasWidth * 0.22,
                        y: canvasHeight * 0.44,
                        label: 'map_paleo'.tr(),
                        icon: Icons.pest_control_rodent_outlined,
                        color: Colors.amber,
                        info: 'Fósiles de pterodáctilos, mamuts y minerales únicos.',
                        roomKey: 'SALA I: Antropología y Paleontología',
                      ),

                      // Sala II: Zoología (Ballena/Jirafa)
                      _buildAnimatedPin(
                        context,
                        x: canvasWidth * 0.48,
                        y: canvasHeight * 0.30,
                        label: 'map_zoo'.tr(),
                        icon: Icons.pets,
                        color: Colors.greenAccent,
                        info: 'Espectacular colección de taxidermia y esqueletos reales.',
                        roomKey: 'SALA II: Zoología y Taxidermia',
                      ),

                      // Sala III: Arqueología (Jarrones)
                      _buildAnimatedPin(
                        context,
                        x: canvasWidth * 0.82,
                        y: canvasHeight * 0.32,
                        label: 'map_archaeo'.tr(),
                        icon: Icons.account_balance,
                        color: Colors.orangeAccent,
                        info: 'Vasijas griegas, romanas y tesoros de excavaciones granadinas.',
                        roomKey: 'SALA III: Arqueología',
                      ),

                      // Sala VI: Modelos Dr. Auzoux (Anatomía)
                      _buildAnimatedPin(
                        context,
                        x: canvasWidth * 0.53,
                        y: canvasHeight * 0.78,
                        label: 'map_anatomy'.tr(),
                        icon: Icons.accessibility_new,
                        color: Colors.redAccent,
                        info: 'Anatomía clástica del siglo XIX de valor incalculable.',
                        roomKey: 'SALA VI: Anatomía y Modelos Auzoux',
                      ),

                      // Sala VII: Física y Química (Laboratorio)
                      _buildAnimatedPin(
                        context,
                        x: canvasWidth * 0.83,
                        y: canvasHeight * 0.71,
                        label: 'map_instruments'.tr(),
                        icon: Icons.science,
                        color: Colors.cyanAccent,
                        info: 'Gabinete histórico con instrumentos científicos originales.',
                        roomKey: 'SALA VII: Instrumentos Científicos',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedPin(
    BuildContext context, {
    required double x,
    required double y,
    required String label,
    required IconData icon,
    required Color color,
    required String info,
    required String roomKey,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color currentBgColor = isDark ? const Color(0xFF080E26) : Colors.white;

    return Positioned(
      left: x - 40,
      top: y - 45,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: () => _showRoomDetails(context, label, info, color, roomKey),
          child: SizedBox(
            width: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: currentBgColor,
                    radius: 22,
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoomDetails(
    BuildContext context,
    String title,
    String info,
    Color color,
    String roomKey,
  ) {
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1), 
              blurRadius: 20, 
              spreadRadius: 5
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'PLANTA PRINCIPAL',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey : Colors.grey[600],
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              info,
              style: TextStyle(
                fontSize: 16,
                color: descColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/collection?room=$roomKey');
                },
                icon: const Icon(Icons.explore_outlined, size: 20),
                label: Text(
                  'map_explore_objects'.tr().toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
    final Color currentBgColor = isDark ? const Color(0xFF080E26) : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: currentBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.museum_outlined, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text(
              'map_museum_title'.tr(),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'map_museum_desc'.tr(),
          style: TextStyle(color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'map_close'.tr().toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}
