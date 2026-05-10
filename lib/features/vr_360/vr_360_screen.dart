import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:easy_localization/easy_localization.dart';
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
      appBar: AppBar(
        title: Text('vr_title'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: PanoramaViewer(
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
    );
  }
}
