import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../../../core/providers/locale_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'map_museum_title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
            onPressed: () => _showMuseumInfo(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF0D1B2A), Color(0xFF000814)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Un lienzo ligeramente más grande que el viewport para permitir un poco de pan
            final canvasWidth = constraints.maxWidth * 1.4;
            final canvasHeight = constraints.maxHeight * 1.3;

            return InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.6,
              boundaryMargin: const EdgeInsets.all(50),
              // Centramos el visor para que el mapa aparezca de frente
              transformationController: TransformationController()
                ..value = Matrix4.translationValues(
                  -(canvasWidth - constraints.maxWidth) / 2,
                  -(canvasHeight - constraints.maxHeight) / 2,
                  0,
                ),
              child: Stack(
                children: [
                  // Capa Blueprint (Fondo)
                  SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: CustomPaint(
                      painter: MuseumBlueprintPainter(
                        corridorLabel: 'map_corridor'.tr(),
                      ),
                    ),
                  ),

                  // Sala I: Paleontología (Ala Norte - Izquierda)
                  _buildPremiumPin(
                    context,
                    x: canvasWidth * 0.26,
                    y: canvasHeight * 0.28,
                    label: 'map_paleo'.tr(),
                    icon: Icons.pest_control_rodent_outlined,
                    color: Colors.amber,
                    info:
                        'Fósiles de pterodáctilos, mamuts y minerales únicos.',
                  ),

                  // Sala II: Zoología (Ala Norte - Centro)
                  _buildPremiumPin(
                    context,
                    x: canvasWidth * 0.5,
                    y: canvasHeight * 0.28,
                    label: 'map_zoo'.tr(),
                    icon: Icons.pets,
                    color: Colors.greenAccent,
                    info:
                        'Espectacular colección de taxidermia y esqueletos reales.',
                  ),

                  // Sala III: Arqueología (Ala Norte - Derecha)
                  _buildPremiumPin(
                    context,
                    x: canvasWidth * 0.74,
                    y: canvasHeight * 0.28,
                    label: 'map_archaeo'.tr(),
                    icon: Icons.account_balance,
                    color: Colors.orangeAccent,
                    info:
                        'Vasijas griegas, romanas y tesoros de excavaciones granadinas.',
                  ),

                  // Sala VI: Modelos Dr. Auzoux (Ala Sur - Izquierda)
                  _buildPremiumPin(
                    context,
                    x: canvasWidth * 0.35,
                    y: canvasHeight * 0.71,
                    label: 'map_anatomy'.tr(),
                    icon: Icons.accessibility_new,
                    color: Colors.redAccent,
                    info:
                        'Anatomía clástica del siglo XIX de valor incalculable.',
                  ),

                  // Sala VII: Física y Química (Ala Sur - Derecha)
                  _buildPremiumPin(
                    context,
                    x: canvasWidth * 0.65,
                    y: canvasHeight * 0.71,
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
    required double x,
    required double y,
    required String label,
    required IconData icon,
    required Color color,
    required String info,
  }) {
    return Positioned(
      left: x - 40,
      top: y - 45,
      child: GestureDetector(
        onTap: () => _showRoomDetails(context, label, info, color),
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
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF1B263B),
                  radius: 20,
                  child: Icon(icon, color: color, size: 22),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B263B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
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
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_on, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              info,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
  final String corridorLabel;

  MuseumBlueprintPainter({required this.corridorLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final blueprintPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final wallPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.5)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final wallFillPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // 1. Dibujar Cuadrícula Técnica
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Definición de Áreas
    final double midX = size.width / 2;
    final double nWingTop = size.height * 0.12;
    final double nWingHeight = size.height * 0.32;
    final double nWingWidth = size.width * 0.82;
    final double nWingLeft = midX - (nWingWidth / 2);

    final double sWingTop = size.height * 0.6;
    final double sWingHeight = size.height * 0.22;
    final double sWingWidth = size.width * 0.65;
    final double sWingLeft = midX - (sWingWidth / 2);

    // --- ALA NORTE (Salas I, II, III) ---
    final Rect northRect = Rect.fromLTWH(
      nWingLeft,
      nWingTop,
      nWingWidth,
      nWingHeight,
    );
    canvas.drawRect(northRect, wallFillPaint);
    canvas.drawRect(northRect, wallPaint);

    // Divisiones Ala Norte
    final double roomWidth = nWingWidth / 3;
    canvas.drawLine(
      Offset(nWingLeft + roomWidth, nWingTop),
      Offset(nWingLeft + roomWidth, nWingTop + nWingHeight),
      blueprintPaint,
    );
    canvas.drawLine(
      Offset(nWingLeft + roomWidth * 2, nWingTop),
      Offset(nWingLeft + roomWidth * 2, nWingTop + nWingHeight),
      blueprintPaint,
    );

    // Detalle de Vitrinas / Pilastras
    _drawVitrinas(
      canvas,
      nWingLeft + 20,
      nWingTop + 20,
      roomWidth - 40,
      nWingHeight - 40,
    );
    _drawVitrinas(
      canvas,
      nWingLeft + roomWidth + 20,
      nWingTop + 20,
      roomWidth - 40,
      nWingHeight - 40,
    );
    _drawVitrinas(
      canvas,
      nWingLeft + roomWidth * 2 + 20,
      nWingTop + 20,
      roomWidth - 40,
      nWingHeight - 40,
    );

    // Puertas Ala Norte
    _drawDetailedDoor(
      canvas,
      Offset(nWingLeft + roomWidth, nWingTop + nWingHeight * 0.6),
      true,
    );
    _drawDetailedDoor(
      canvas,
      Offset(nWingLeft + roomWidth * 2, nWingTop + nWingHeight * 0.6),
      true,
    );

    // Numeración de salas (Norte)
    _drawRoomTag(canvas, "S-I", Offset(nWingLeft + 15, nWingTop + 15));
    _drawRoomTag(
      canvas,
      "S-II",
      Offset(nWingLeft + roomWidth + 15, nWingTop + 15),
    );
    _drawRoomTag(
      canvas,
      "S-III",
      Offset(nWingLeft + roomWidth * 2 + 15, nWingTop + 15),
    );

    // --- ALA SUR (Salas VI, VII) ---
    final Rect southRect = Rect.fromLTWH(
      sWingLeft,
      sWingTop,
      sWingWidth,
      sWingHeight,
    );
    canvas.drawRect(southRect, wallFillPaint);
    canvas.drawRect(southRect, wallPaint);

    // División Ala Sur
    canvas.drawLine(
      Offset(midX, sWingTop),
      Offset(midX, sWingTop + sWingHeight),
      blueprintPaint,
    );
    _drawDetailedDoor(canvas, Offset(midX, sWingTop + sWingHeight * 0.4), true);

    // Vitrinas Sur
    _drawVitrinas(
      canvas,
      sWingLeft + 20,
      sWingTop + 20,
      (sWingWidth / 2) - 40,
      sWingHeight - 40,
    );
    _drawVitrinas(
      canvas,
      midX + 20,
      sWingTop + 20,
      (sWingWidth / 2) - 40,
      sWingHeight - 40,
    );

    // Numeración de salas (Sur)
    _drawRoomTag(canvas, "S-VI", Offset(sWingLeft + 15, sWingTop + 15));
    _drawRoomTag(canvas, "S-VII", Offset(midX + 15, sWingTop + 15));

    // --- PASILLOS Y CONEXIONES ---
    final corridorPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double corridorY = nWingTop + nWingHeight;
    final double corridorH = sWingTop - corridorY;
    final double corridorW = 80;

    final Rect corridorRect = Rect.fromCenter(
      center: Offset(midX, corridorY + (corridorH / 2)),
      width: corridorW,
      height: corridorH,
    );
    canvas.drawRect(corridorRect, wallFillPaint);
    canvas.drawRect(corridorRect, corridorPaint);

    _drawDetailedDoor(
      canvas,
      Offset(midX - corridorW / 2, corridorY + corridorH / 2),
      false,
    );
    _drawDetailedDoor(
      canvas,
      Offset(midX + corridorW / 2, corridorY + corridorH / 2),
      false,
    );

    // 3. Anotaciones de Texto Detalladas
    _drawText(
      canvas,
      corridorLabel.toUpperCase(),
      Offset(midX + 3, corridorY + corridorH * 0.4),
      rot: 90,
      size: 7,
    );
    _drawText(
      canvas,
      "PLANTA PRINCIPAL - SECCIÓN TÉCNICA",
      Offset(nWingLeft, nWingTop - 25),
      size: 9,
      bold: true,
    );
    _drawText(
      canvas,
      "AC-MOD-2026 / PADRE SUÁREZ",
      Offset(sWingLeft, sWingTop + sWingHeight + 20),
      size: 7,
    );

    // 4. Cotas de Medida
    final cotaPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    _drawCota(
      canvas,
      Offset(nWingLeft - 20, nWingTop),
      Offset(nWingLeft - 20, nWingTop + nWingHeight),
      "14.2m",
      cotaPaint,
    );
    _drawCota(
      canvas,
      Offset(nWingLeft, nWingTop - 40),
      Offset(nWingLeft + nWingWidth, nWingTop - 40),
      "32.8m",
      cotaPaint,
    );
  }

  void _drawVitrinas(Canvas canvas, double x, double y, double w, double h) {
    final vPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    // Dibujamos un patrón de cuadrículas internas tipo vitrina
    int rows = 2;
    int cols = (w / 40).floor();
    if (cols < 1) cols = 1;

    for (int i = 0; i <= rows; i++) {
      canvas.drawLine(
        Offset(x, y + i * (h / rows)),
        Offset(x + w, y + i * (h / rows)),
        vPaint,
      );
    }
    for (int i = 0; i <= cols; i++) {
      canvas.drawLine(
        Offset(x + i * (w / cols), y),
        Offset(x + i * (w / cols), y + h),
        vPaint,
      );
    }
  }

  void _drawDetailedDoor(Canvas canvas, Offset pos, bool vertical) {
    final doorPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.7)
      ..strokeWidth = 2.0;
    if (vertical) {
      canvas.drawLine(
        pos + const Offset(0, -15),
        pos + const Offset(0, 15),
        doorPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: pos + const Offset(0, -15), radius: 25),
        0,
        1.2,
        false,
        doorPaint,
      );
    } else {
      canvas.drawLine(
        pos + const Offset(-15, 0),
        pos + const Offset(15, 0),
        doorPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: pos + const Offset(-15, 0), radius: 25),
        -1.5,
        1.2,
        false,
        doorPaint,
      );
    }
  }

  void _drawRoomTag(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.blueAccent.withValues(alpha: 0.6),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos, {
    double rot = 0,
    double size = 8,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.25),
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rot * 0.0174533);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawCota(
    Canvas canvas,
    Offset start,
    Offset end,
    String text,
    Paint paint,
  ) {
    canvas.drawLine(start, end, paint);
    // Trazos finales
    bool isVertical = (start.dx == end.dx);
    if (isVertical) {
      canvas.drawLine(
        start + const Offset(-5, 0),
        start + const Offset(5, 0),
        paint,
      );
      canvas.drawLine(
        end + const Offset(-5, 0),
        end + const Offset(5, 0),
        paint,
      );
    } else {
      canvas.drawLine(
        start + const Offset(0, -5),
        start + const Offset(0, 5),
        paint,
      );
      canvas.drawLine(
        end + const Offset(0, -5),
        end + const Offset(0, 5),
        paint,
      );
    }
    _drawText(
      canvas,
      text,
      (start + end) / 2 +
          (isVertical ? const Offset(-30, 0) : const Offset(0, -15)),
      size: 7,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
