import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../main_navigation/providers/collection_provider.dart';
import '../main_navigation/providers/catalog_provider.dart';

class ArScreen extends ConsumerStatefulWidget {
  const ArScreen({super.key});

  @override
  ConsumerState<ArScreen> createState() => _ArScreenState();
}

class _ArScreenState extends ConsumerState<ArScreen> {
  // Estado actual: escaneando QR o visualizando el modelo
  bool _isScanning = true;
  String? _scannedModelUrl;

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    final catalog = ref.read(catalogProvider).items;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        final item = catalog.firstWhere(
          (i) => i.id == code || i.fileName == code,
          orElse: () => CatalogItem(
            id: '',
            name: '',
            fileName: '',
            description: '',
            type: CatalogItemType.unknown,
            room: 'General',
          ),
        );

        if (item.type != CatalogItemType.unknown) {
          // Desbloqueamos el ítem
          ref.read(collectionProvider.notifier).unlockItem(item.id);

          if (item.type == CatalogItemType.environment360) {
            // Si es un entorno 360, vamos a la pantalla de VR en lugar del AR Viewer
            FirebaseAnalytics.instance.logEvent(
              name: 'ar_scan_success',
              parameters: {'item_id': item.id, 'type': 'environment360'},
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ar_360_unlocked'.tr(args: [item.name]))),
            );
            context.push('/vr_explore?file=${item.fileName}');
            _resetScanner();
          } else {
            // Es una pieza 3D, la mostramos aquí en el visor AR
            FirebaseAnalytics.instance.logEvent(
              name: 'ar_scan_success',
              parameters: {'item_id': item.id, 'type': 'piece3D'},
            );
            final baseUrl = dotenv.env['R2_PUBLIC_URL'] ?? '';
            setState(() {
              _scannedModelUrl = Uri.encodeFull('$baseUrl/${item.fileName}');
              _isScanning = false;
            });
          }
          break;
        } else {
          // Caso de código inválido o ajeno
          FirebaseAnalytics.instance.logEvent(
            name: 'ar_scan_error',
            parameters: {'scanned_code': code},
          );
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('ar_qr_error'.tr())));
          // break para no inundar de snackbars si lee múltiples veces el mismo inválido
          break;
        }
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _scannedModelUrl = null;
      _isScanning = true;
    });
  }

  // Simula la lectura de un QR válido (útil para pruebas en Web/Emulador)
  void _simulateScan() {
    final catalog = ref.read(catalogProvider).items;
    if (catalog.isEmpty) return;

    // Buscamos forzosamente la primera pieza 3D real para el test AR
    final first3DItem = catalog.firstWhere(
      (i) => i.type == CatalogItemType.piece3D,
      orElse: () => catalog.first,
    );

    ref.read(collectionProvider.notifier).unlockItem(first3DItem.id);

    FirebaseAnalytics.instance.logEvent(
      name: 'ar_scan_simulated',
      parameters: {'item_id': first3DItem.id},
    );

    final baseUrl = dotenv.env['R2_PUBLIC_URL'] ?? '';
    setState(() {
      _scannedModelUrl = Uri.encodeFull('$baseUrl/${first3DItem.fileName}');
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Forzar reconstrucción por idioma
    final _ = context.locale;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isScanning ? 'ar_scan_title'.tr() : 'ar_viewing_piece'.tr(),
        ),
        actions: [
          if (!_isScanning)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'ar_scan_another'.tr(),
              onPressed: _resetScanner,
            ),
        ],
      ),
      body: _isScanning ? _buildScannerView() : _buildModelView(),
      floatingActionButton:
          _isScanning && (int.tryParse(dotenv.env['TESTER'] ?? '0') == 1)
          ? FloatingActionButton.extended(
              onPressed: _simulateScan,
              icon: const Icon(Icons.science),
              label: Text('ar_simulate'.tr()),
            )
          : null,
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: _onDetect,
          errorBuilder: (BuildContext context, MobileScannerException error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 80),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white),
                        children: [
                          TextSpan(text: 'ar_camera_denied'.tr()),
                          if (error.toString().contains('NotAllowedError'))
                            const TextSpan(
                              text: '\nNotAllowedError: Permission dismissed',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Overlay visual para guiar al usuario
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.greenAccent, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_scanner,
                color: Colors.white54,
                size: 80,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Text(
            'ar_point_qr'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.black54, // Fondo para legibilidad
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelView() {
    if (_scannedModelUrl == null) return const SizedBox.shrink();

    return Stack(
      children: [
        ModelViewer(
          src: _scannedModelUrl!,
          alt: 'Artefacto 3D en AR',
          ar: true,
          arModes: const ['scene-viewer', 'webxr', 'quick-look'],
          autoRotate: true,
          cameraControls: true,
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Puedes rotar y escalar el modelo libremente. Toca el botón de AR para proyectarlo en tu espacio físico.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
