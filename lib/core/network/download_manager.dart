import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Gestor de descargas para "Museo Padre Suárez".
///
/// Selecciona automáticamente la fuente de assets:
///   - Cloudflare R2 si R2_PUBLIC_URL está definida en .env
///   - GitHub Raw como fallback si R2_PUBLIC_URL está vacía o ausente
class DownloadManager {
  final Dio _dio;
  final String _baseUrl;
  final bool _usingR2;

  DownloadManager({Dio? dio})
    : _dio = dio ?? Dio(),
      _usingR2 = (dotenv.env['R2_PUBLIC_URL'] ?? '').isNotEmpty,
      _baseUrl = (dotenv.env['R2_PUBLIC_URL'] ?? '').isNotEmpty
          ? dotenv.env['R2_PUBLIC_URL']!
          : dotenv.env['GITHUB_RAW_URL'] ?? '' {
    debugPrint(
      '[DownloadManager] Fuente de assets: ${_usingR2 ? "☁️ Cloudflare R2 ($_baseUrl)" : "🐙 GitHub ($_baseUrl)"}',
    );
  }

  /// Descarga un archivo desde [urlOrFileName] y lo guarda en caché local.
  /// Si solo se pasa un nombre de archivo, construye la URL completa usando [_baseUrl].
  /// En Web, devuelve la URL directamente (sin caché local).
  Future<String?> downloadAndCacheFile(
    String urlOrFileName,
    String fileName, {
    Function(int received, int total)? onReceiveProgress,
  }) async {
    final String url = urlOrFileName.startsWith('http')
        ? urlOrFileName
        : '$_baseUrl/${Uri.encodeComponent(urlOrFileName)}';

    // En Web no hay acceso a dart:io, devolvemos la URL directamente
    if (kIsWeb) {
      return url;
    }

    try {
      final directory = await getTemporaryDirectory();
      final String savePath = '${directory.path}/$fileName';
      final File file = File(savePath);

      // Si ya existe en caché, no volvemos a descargar
      if (await file.exists()) {
        debugPrint('[DownloadManager] Usando caché: $fileName');
        return savePath;
      }

      debugPrint('[DownloadManager] Descargando: $url');
      await _dio.download(url, savePath, onReceiveProgress: onReceiveProgress);

      return savePath;
    } catch (e) {
      debugPrint('[DownloadManager] Error al descargar "$fileName": $e');
      return null;
    }
  }

  /// Elimina un archivo específico de la caché.
  Future<void> deleteFromCache(String fileName) async {
    if (kIsWeb) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    if (await file.exists()) await file.delete();
  }

  /// Limpia toda la caché de modelos descargados.
  Future<void> clearCache() async {
    if (kIsWeb) return;
    final directory = await getTemporaryDirectory();
    if (await directory.exists()) {
      directory.listSync().whereType<File>().forEach((f) => f.deleteSync());
    }
  }
}
