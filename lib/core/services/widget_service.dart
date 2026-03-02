import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';

class WidgetService {
  static const String _androidWidgetName = 'MuseumWidgetProvider';
  static const String _iOSWidgetName = 'MuseumWidget';

  /// Actualiza el widget con la última noticia o descubrimiento
  static Future<void> updateHomeWidget({
    required String title,
    required String message,
    String? lastItem,
  }) async {
    // Los Home Widgets no existen en la versión Web
    if (kIsWeb) return;

    try {
      // Guardar datos para Android e iOS
      await HomeWidget.saveWidgetData<String>('title', title);
      await HomeWidget.saveWidgetData<String>('message', message);
      if (lastItem != null) {
        await HomeWidget.saveWidgetData<String>('last_item', lastItem);
      }

      // Disparar la actualización del widget nativo
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _iOSWidgetName,
      );

      debugPrint('Widget actualizado: $title - $message');
    } catch (e) {
      debugPrint('Error actualizando Home Widget: $e');
    }
  }
}
