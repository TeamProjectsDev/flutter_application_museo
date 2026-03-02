import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/locale_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar cambios de idioma para refrescar tr()
    ref.watch(localeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'app_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            onPressed: () => _showMuseumInfo(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [const Color(0xFF0D1B2A), const Color(0xFF000814)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.5,
              boundaryMargin: const EdgeInsets.all(200),
              child: Stack(
                children: [
                  // Capa Blueprint
                  SizedBox(
                    width: constraints.maxWidth * 2,
                    height: constraints.maxHeight * 2,
                    child: CustomPaint(painter: MuseumBlueprintPainter()),
                  ),

                  // Sala I: Paleontología
                  _buildPremiumPin(
                    context,
                    top: 0.35,
                    left: 0.3,
                    label: 'map_paleo'.tr(),
                    icon: Icons.pest_control_rodent_outlined,
                    color: Colors.amber,
                    info:
                        'Fósiles de pterodáctilos, mamuts y minerales únicos.',
                  ),

                  // Sala II: Zoología
                  _buildPremiumPin(
                    context,
                    top: 0.35,
                    left: 1.0,
                    label: 'map_zoo'.tr(),
                    icon: Icons.pets,
                    color: Colors.greenAccent,
                    info:
                        'Espectacular colección de taxidermia y esqueletos reales.',
                  ),

                  // Sala III: Arqueología
                  _buildPremiumPin(
                    context,
                    top: 0.35,
                    left: 1.6,
                    label: 'map_archaeo'.tr(),
                    icon: Icons.account_balance,
                    color: Colors.orangeAccent,
                    info:
                        'Vasijas griegas, romanas y tesoros de excavaciones granadinas.',
                  ),

                  // Sala VI: Modelos Dr. Auzoux
                  _buildPremiumPin(
                    context,
                    top: 1.25,
                    left: 0.45,
                    label: 'map_anatomy'.tr(),
                    icon: Icons.accessibility_new,
                    color: Colors.redAccent,
                    info:
                        'Anatomía clástica del siglo XIX de valor incalculable.',
                  ),

                  // Sala VII: Física y Química
                  _buildPremiumPin(
                    context,
                    top: 1.25,
                    left: 1.45,
                    label: 'map_instruments'.tr(),
                    icon: Icons.science,
                    color: Colors.cyanAccent,
                    info:
                        'Gabinete histórico con instrumentos científicos originales.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumPin(
    BuildContext context, {
    required double top,
    required double left,
    required String label,
    required IconData icon,
    required Color color,
    required String info,
  }) {
    return Positioned(
      top: MediaQuery.of(context).size.height * top,
      left: MediaQuery.of(context).size.width * left,
      child: GestureDetector(
        onTap: () => _showRoomDetails(context, label, info, color),
        child: Column(
          children: [
            // Icono con efecto de pulso / brillo
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1B263B),
                radius: 24,
                child: Icon(icon, color: color, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            // Etiqueta estilizada
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B263B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRoomDetails(
    BuildContext context,
    String title,
    String info,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B263B), Color(0xFF0D1B2A)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.location_on, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              info,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/collection?room=$title');
                },
                icon: const Icon(Icons.explore_outlined),
                label: Text('map_explore_objects'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: color.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showMuseumInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        title: Text(
          'map_museum_title'.tr(),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'map_museum_desc'.tr(),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'map_close'.tr(),
              style: const TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}

class MuseumBlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blueprintPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final wallFillPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // 1. Cuadrícula Técnica
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Dibujo Estructural del Plano
    final path = Path();

    // Ala Norte (Sección Principal)
    double northY = size.height * 0.15;
    double northH = size.height * 0.25;
    Rect northRect = Rect.fromLTWH(
      size.width * 0.1,
      northY,
      size.width * 1.8,
      northH,
    );
    path.addRect(northRect);
    canvas.drawRect(northRect, wallFillPaint);

    // Ala Sur
    double southY = size.height * 0.6;
    double southH = size.height * 0.25;
    Rect southRect = Rect.fromLTWH(
      size.width * 0.1,
      southY,
      size.width * 1.8,
      southH,
    );
    path.addRect(southRect);
    canvas.drawRect(southRect, wallFillPaint);

    // Conexiones de Pasillos
    path.moveTo(size.width * 0.5, northY + northH);
    path.lineTo(size.width * 0.5, southY);

    path.moveTo(size.width * 1.5, northY + northH);
    path.lineTo(size.width * 1.5, southY);

    canvas.drawPath(path, blueprintPaint);

    // 3. Detalles de "Arquitecto"
    final detailPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    // Cotas / Medidas ficticias
    canvas.drawLine(
      Offset(size.width * 0.05, northY),
      Offset(size.width * 0.05, northY + northH),
      detailPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.04, northY),
      Offset(size.width * 0.06, northY),
      detailPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.04, northY + northH),
      Offset(size.width * 0.06, northY + northH),
      detailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
