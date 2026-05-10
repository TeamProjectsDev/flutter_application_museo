import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import '../main_navigation/providers/catalog_provider.dart';

class Vr360Screen extends StatelessWidget {
  final String? panoramaFileName;
  const Vr360Screen({super.key, this.panoramaFileName});

  @override
  Widget build(BuildContext context) {
    final String panoramaUrl = CatalogItem.buildCloudinaryUrl(
      panoramaFileName ?? 'entorno_360.jpg',
    );

    FirebaseAnalytics.instance.logEvent(
      name: 'view_item_360',
      parameters: {'item_name': panoramaFileName ?? "entorno_360.jpg"},
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PanoramaViewer(
            animSpeed: 1.0,
            sensorControl: SensorControl.orientation,
            child: Image.network(
              panoramaUrl,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
          // 🛡️ BOTÓN VOLVER INMERSIVO
          Positioned(
            top: 40,
            left: 20,
            child: SafeArea(
              child: InkWell(
                onTap: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go('/collection'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
