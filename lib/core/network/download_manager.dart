import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Gestor de descargas personalizado para "Museo Vivo 4.0".
/// Se encarga de descargar de forma asíncrona archivos pesados (modelos 3D .glb/.gltf)
/// desde Cloudflare R2 y almacenarlos localmente en la caché del dispositivo.
class DownloadManager {
  final Dio _dio;
  final String _baseUrl;

  DownloadManager({Dio? dio})
    : _dio = dio ?? Dio(),
      _baseUrl = dotenv.env['GITHUB_RAW_URL'] ?? '';

  /// Descarga un archivo desde una [urlOrFileName] y lo guarda en la caché.
  /// Si solo se pasa un nombre de archivo, usará la [_baseUrl] de R2.
  ///
  /// Si el archivo ya existe en caché, retorna su ruta local sin volver a descargarlo.
  /// [onReceiveProgress] es opcional y permite monitorear el progreso de descarga.
  Future<String?> downloadAndCacheFile(
    String urlOrFileName,
    String fileName, {
    Function(int received, int total)? onReceiveProgress,
  }) async {
    final String url = urlOrFileName.startsWith('http')
        ? urlOrFileName
        : Uri.encodeFull('$_baseUrl/$urlOrFileName');
    // Si estamos en la web, no gestionamos caché pesada localmente
    // debido a las restricciones de dart:io en navegadores web.
    // Simplemente devolvemos la misma URL para que el visor cargue en red.
    if (kIsWeb) {
      return url;
    }

    try {
      // 1. Obtener el directorio temporal (caché) del dispositivo
      final directory = await getTemporaryDirectory();
      final String savePath = '${directory.path}/$fileName';

      final File file = File(savePath);

      // 2. Comprobar si el modelo ya está en caché para evitar redescargas
      if (await file.exists()) {
        return savePath;
      }

      // 3. Descargar el archivo desde R2 si no existe localmente
      await _dio.download(url, savePath, onReceiveProgress: onReceiveProgress);

      return savePath;
    } catch (e) {
      // Registrar error en caso de fallo u omitir según la lógica del proyecto
      debugPrint('Error al descargar el archivo desde R2: $e');
      return null;
    }
  }

  /// Elimina un archivo específico de la caché.
  Future<void> deleteFromCache(String fileName) async {
    if (kIsWeb) return;

    final directory = await getTemporaryDirectory();
    final String path = '${directory.path}/$fileName';
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Limpia toda la caché de modelos descargados (opcional para liberar espacio).
  Future<void> clearCache() async {
    if (kIsWeb) return;

    final directory = await getTemporaryDirectory();
    if (await directory.exists()) {
      directory.listSync().forEach((entity) {
        if (entity is File) {
          entity.deleteSync();
        }
      });
    }
  }
}
