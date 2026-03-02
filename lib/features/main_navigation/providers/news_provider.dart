import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:dart_rss/dart_rss.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb

class NewsArticle {
  final String title;
  final String link;
  final String description;
  final String imageUrl;
  final String category;
  final DateTime date;

  NewsArticle({
    required this.title,
    required this.link,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.date,
  });

  factory NewsArticle.fromRss(RssItem item) {
    // 1. Intentar extraer imagen de Media RSS (media:content)
    String? imageUrl;

    if (item.media?.contents.isNotEmpty ?? false) {
      imageUrl = item.media!.contents.first.url;
    }
    // 2. Intentar de enclosures
    else if (item.enclosure?.url != null) {
      imageUrl = item.enclosure!.url;
    }
    // 3. Fallback: Buscar una imagen en la descripción (regex)
    else if (item.description != null) {
      final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"');
      final match = imgRegex.firstMatch(item.description!);
      if (match != null) {
        imageUrl = match.group(1);
      }
    }

    // Si todo falla, usar un seed aleatorio pero coherente
    imageUrl ??= 'https://picsum.photos/seed/${item.title.hashCode}/800/400';

    // Limpieza de descripción (quitar HTML si lo hay)
    String cleanDesc = item.description ?? '';
    // Eliminar tags HTML
    cleanDesc = cleanDesc.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    // Eliminar espacios extra o caracteres raros de CDATA
    cleanDesc = cleanDesc.replaceAll('&nbsp;', ' ');

    if (cleanDesc.length > 180) {
      cleanDesc = '${cleanDesc.substring(0, 177)}...';
    }

    // Formateo de fecha
    DateTime pubDate = DateTime.now();
    try {
      // dart_rss maneja varios formatos, pero por si acaso
      if (item.pubDate != null) {
        // Formato estándar RFC 822/1123 suele venir en RSS
        pubDate = DateFormat(
          "EEE, dd MMM yyyy HH:mm:ss Z",
        ).parse(item.pubDate!);
      }
    } catch (_) {
      // Si falla el parseo, usamos la fecha actual
    }

    return NewsArticle(
      title: item.title ?? 'Sin título',
      link: item.link ?? '',
      description: cleanDesc,
      imageUrl: imageUrl,
      category: item.categories.isNotEmpty
          ? (item.categories.first.value ?? 'Ciencia')
          : 'Ciencia',
      date: pubDate,
    );
  }
}

class NewsState {
  final List<NewsArticle> articles;
  final bool isLoading;
  final String? error;

  NewsState({this.articles = const [], this.isLoading = false, this.error});
}

class NewsNotifier extends StateNotifier<NewsState> {
  // Lista de feeds para mayor variedad
  static const List<String> _feedUrls = [
    'http://www.agenciasinc.es/feed/noticias',
    'http://www.agenciasinc.es/feed/reportajes',
    'https://www.sciencedaily.com/rss/all.xml',
    'https://www.smithsonianmag.com/rss/science/',
    'https://www.smithsonianmag.com/rss/history/',
    'https://www.nature.com/nature.rss',
    'https://www.eurekalert.org/rss/science_news.xml',
  ];

  // Proxies de CORS para Web (en orden de preferencia)
  static const List<String> _corsProxies = [
    'https://corsproxy.io/?',
    'https://api.allorigins.win/raw?url=',
    'https://cors.lol/?url=',
  ];

  NewsNotifier() : super(NewsState(isLoading: true)) {
    fetchNews();
  }

  /// Intenta descargar un feed probando varios proxies si falla
  Future<http.Response?> _fetchWithFallback(String url) async {
    if (!kIsWeb) {
      try {
        return await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
      } catch (e) {
        return null;
      }
    }

    // Para Web: Probar cada proxy en orden
    for (String proxy in _corsProxies) {
      try {
        final proxyUrl = '$proxy${Uri.encodeComponent(url)}';
        final response = await http
            .get(Uri.parse(proxyUrl))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          return response;
        }
      } catch (e) {
        debugPrint('Proxy $proxy falló para $url: $e');
        continue; // Probar el siguiente
      }
    }
    return null;
  }

  Future<void> fetchNews() async {
    try {
      state = NewsState(articles: state.articles, isLoading: true);

      // Cargamos todos los feeds en paralelo, cada uno con su propia lógica de reintento
      final responses = await Future.wait(
        _feedUrls.map((url) => _fetchWithFallback(url)),
      );

      List<NewsArticle> allArticles = [];

      for (var response in responses) {
        if (response != null && response.statusCode == 200) {
          // Verificación para evitar parsear HTML de error como si fuera XML
          final isHtml =
              response.body.trim().toLowerCase().startsWith('<html') ||
              response.body.trim().toLowerCase().startsWith('<!doctype');

          if (!isHtml) {
            try {
              final feed = RssFeed.parse(response.body);
              final articles = feed.items
                  .map((item) => NewsArticle.fromRss(item))
                  .toList();
              allArticles.addAll(articles);
            } catch (e) {
              debugPrint('Error parseando feed (posible respuesta no-XML): $e');
            }
          }
        }
      }

      // Ordenar por fecha descendente (más recientes primero)
      allArticles.sort((a, b) => b.date.compareTo(a.date));

      state = NewsState(
        articles: allArticles,
        isLoading: false,
        error: allArticles.isEmpty
            ? 'No se pudieron cargar noticias tras varios reintentos'
            : null,
      );
    } catch (e) {
      state = NewsState(
        articles: state.articles,
        isLoading: false,
        error: 'Error crítico de red: $e',
      );
    }
  }
}

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier();
});
