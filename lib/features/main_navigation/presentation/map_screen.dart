import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showMuseumInfo(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            maxScale: 3.0,
            child: Stack(
              children: [
                // Fondo: Plano Estilizado del Instituto Histórico
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(color: Colors.blueGrey.shade900),
                  child: CustomPaint(painter: MuseumFloorPainter()),
                ),

                // Sala I: Paleontología
                _buildRoomPin(
                  context,
                  top: 0.25,
                  left: 0.2,
                  label: 'map_paleo'.tr(),
                  icon: Icons.pest_control_rodent_outlined, // Fósil simulado
                  color: Colors.orange,
                  info: 'Fósiles, minerales y restos prehistóricos.',
                ),

                // Sala II: Zoología
                _buildRoomPin(
                  context,
                  top: 0.25,
                  left: 0.5,
                  label: 'map_zoo'.tr(),
                  icon: Icons.pets,
                  color: Colors.green,
                  info: 'Colección masiva de animales disecados y taxidermia.',
                ),

                // Sala III: Arqueología
                _buildRoomPin(
                  context,
                  top: 0.25,
                  left: 0.8,
                  label: 'map_archaeo'.tr(),
                  icon: Icons.account_balance,
                  color: Colors.brown,
                  info: 'Piezas antiguas y restos de excavaciones científicas.',
                ),

                // Sala VI: Modelos Dr. Auzoux
                _buildRoomPin(
                  context,
                  top: 0.65,
                  left: 0.25,
                  label: 'map_anatomy'.tr(),
                  icon: Icons.accessibility_new,
                  color: Colors.redAccent,
                  info: 'Modelos clásticos del Dr. Auzoux (siglo XIX).',
                ),

                // Sala VII: Física y Química
                _buildRoomPin(
                  context,
                  top: 0.65,
                  left: 0.75,
                  label: 'map_instruments'.tr(),
                  icon: Icons.science,
                  color: Colors.blue,
                  info: 'Gabinete de Física y Química Martínez Aguirre.',
                ),

                // Pasillo Central: Invertebrados
                Positioned(
                  top: 0.45,
                  left: 0.4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'map_corridor'.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomPin(
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black45),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: color, radius: 8),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(info, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Cerrar panel
                  context.go('/collection?room=$title'); // Navegar con filtro
                },
                icon: const Icon(Icons.explore),
                label: Text('map_explore_objects'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMuseumInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('map_museum_title'.tr()),
        content: Text('map_museum_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('map_close'.tr()),
          ),
        ],
      ),
    );
  }
}

class MuseumFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Dibujamos una estructura simétrica simplificada del Instituto
    final path = Path();

    // Ala Oeste (Donde está el museo)
    path.addRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.2,
        size.width * 0.8,
        size.height * 0.2,
      ),
    );

    // Ala Este
    path.addRect(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.6,
        size.width * 0.8,
        size.height * 0.2,
      ),
    );

    // Cuerpo Central (Pasillo)
    path.moveTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.5, size.height * 0.6);

    canvas.drawPath(path, paint);

    // Cuadrícula de fondo para el "feeling" técnico
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
