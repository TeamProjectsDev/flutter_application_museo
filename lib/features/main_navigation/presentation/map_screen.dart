import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../../../core/providers/locale_provider.dart';

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
    ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'map_museum_title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
            onPressed: () => _showMuseumInfo(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              theme.brightness == Brightness.dark ? const Color(0xFF0D1B2A) : const Color(0xFFF5F5F5),
              theme.brightness == Brightness.dark ? const Color(0xFF000814) : const Color(0xFFE0E0E0),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth * 1.6;
            final canvasHeight = constraints.maxHeight * 1.4;

            return InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.5,
              boundaryMargin: const EdgeInsets.all(100),
              transformationController: TransformationController()
                ..value = Matrix4.translationValues(
                  -(canvasWidth - constraints.maxWidth) / 2,
                  -(canvasHeight - constraints.maxHeight) / 2,
                  0,
                ),
              child: Stack(
                children: [
                  // Capa Blueprint con profundidad
                  SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: CustomPaint(
                      painter: MuseumBlueprintPainter(
                        corridorLabel: 'map_corridor'.tr(),
                        isDark: theme.brightness == Brightness.dark,
                      ),
                    ),
                  ),

                  // Sala I: Paleontología
                  _buildAnimatedPin(
                    context,
                    x: canvasWidth * 0.28,
                    y: canvasHeight * 0.32,
                    label: 'map_paleo'.tr(),
                    icon: Icons.pest_control_rodent_outlined,
                    color: Colors.amber,
                    info: 'Fósiles de pterodáctilos, mamuts y minerales únicos.',
                    roomKey: 'map_paleo',
                  ),

                  // Sala II: Zoología
                  _buildAnimatedPin(
                    context,
                    x: canvasWidth * 0.5,
                    y: canvasHeight * 0.32,
                    label: 'map_zoo'.tr(),
                    icon: Icons.pets,
                    color: Colors.greenAccent,
                    info: 'Espectacular colección de taxidermia y esqueletos reales.',
                    roomKey: 'map_zoo',
                  ),

                  // Sala III: Arqueología
                  _buildAnimatedPin(
                    context,
                    x: canvasWidth * 0.72,
                    y: canvasHeight * 0.32,
                    label: 'map_archaeo'.tr(),
                    icon: Icons.account_balance,
                    color: Colors.orangeAccent,
                    info: 'Vasijas griegas, romanas y tesoros de excavaciones granadinas.',
                    roomKey: 'map_archaeo',
                  ),

                  // Sala VI: Modelos Dr. Auzoux
                  _buildAnimatedPin(
                    context,
                    x: canvasWidth * 0.38,
                    y: canvasHeight * 0.68,
                    label: 'map_anatomy'.tr(),
                    icon: Icons.accessibility_new,
                    color: Colors.redAccent,
                    info: 'Anatomía clástica del siglo XIX de valor incalculable.',
                    roomKey: 'map_anatomy',
                  ),

                  // Sala VII: Física y Química
                  _buildAnimatedPin(
                    context,
                    x: canvasWidth * 0.62,
                    y: canvasHeight * 0.68,
                    label: 'map_instruments'.tr(),
                    icon: Icons.science,
                    color: Colors.cyanAccent,
                    info: 'Gabinete histórico con instrumentos científicos originales.',
                    roomKey: 'map_instruments',
                  ),
                ],
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
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    radius: 22,
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 8,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
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
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'PLANTA PRINCIPAL',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.museum_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'map_museum_title'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'map_museum_desc'.tr(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'map_close'.tr().toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class MuseumBlueprintPainter extends CustomPainter {
  final String corridorLabel;
  final bool isDark;

  MuseumBlueprintPainter({required this.corridorLabel, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final accentColor = isDark ? Colors.blueAccent : const Color(0xFF2B5797);
    
    final blueprintPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final wallPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final wallFillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // 1. Grid
    final gridPaint = Paint()..color = accentColor.withValues(alpha: 0.1);
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    final double midX = size.width / 2;
    final double nWingTop = size.height * 0.15;
    final double nWingHeight = size.height * 0.35;
    final double nWingWidth = size.width * 0.8;
    final double nWingLeft = midX - (nWingWidth / 2);

    final double sWingTop = size.height * 0.65;
    final double sWingHeight = size.height * 0.25;
    final double sWingWidth = size.width * 0.6;
    final double sWingLeft = midX - (sWingWidth / 2);

    // --- ALA NORTE ---
    final Rect northRect = Rect.fromLTWH(nWingLeft, nWingTop, nWingWidth, nWingHeight);
    
    // Sombra isométrica
    canvas.drawRect(northRect.shift(const Offset(4, 4)), shadowPaint);
    
    canvas.drawRect(northRect, wallFillPaint);
    canvas.drawRect(northRect, wallPaint);

    // Divisiones
    final double roomWidth = nWingWidth / 3;
    canvas.drawLine(Offset(nWingLeft + roomWidth, nWingTop), Offset(nWingLeft + roomWidth, nWingTop + nWingHeight), blueprintPaint);
    canvas.drawLine(Offset(nWingLeft + roomWidth * 2, nWingTop), Offset(nWingLeft + roomWidth * 2, nWingTop + nWingHeight), blueprintPaint);

    // --- ALA SUR ---
    final Rect southRect = Rect.fromLTWH(sWingLeft, sWingTop, sWingWidth, sWingHeight);
    canvas.drawRect(southRect.shift(const Offset(4, 4)), shadowPaint);
    canvas.drawRect(southRect, wallFillPaint);
    canvas.drawRect(southRect, wallPaint);

    // División Sur
    canvas.drawLine(Offset(midX, sWingTop), Offset(midX, sWingTop + sWingHeight), blueprintPaint);

    // --- CONEXIÓN ---
    final double corridorY = nWingTop + nWingHeight;
    final double corridorH = sWingTop - corridorY;
    final double corridorW = 100;
    final Rect corridorRect = Rect.fromCenter(center: Offset(midX, corridorY + (corridorH / 2)), width: corridorW, height: corridorH);
    canvas.drawRect(corridorRect, wallFillPaint);
    canvas.drawRect(corridorRect, blueprintPaint);

    // Etiquetas
    _drawText(canvas, corridorLabel.toUpperCase(), Offset(midX + 5, corridorY + corridorH * 0.4), rot: 90, size: 8, color: accentColor);
    _drawText(canvas, "IES PADRE SUÁREZ - GABINETE TÉCNICO", Offset(nWingLeft, nWingTop - 30), size: 10, bold: true, color: accentColor);
  }

  void _drawText(Canvas canvas, String text, Offset pos, {double rot = 0, double size = 8, bool bold = false, required Color color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: 0.6),
          fontSize: size,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: 1.5,
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
