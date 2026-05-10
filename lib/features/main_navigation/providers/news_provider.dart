import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

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


  NewsNotifier() : super(NewsState(isLoading: true)) {
    fetchNews();
  }


  Future<void> fetchNews() async {
    try {
      state = NewsState(articles: state.articles, isLoading: true);

      List<NewsArticle> allArticles = [];

      // Para Web, usamos un conversor de RSS a JSON profesional que salta el CORS
      // Para nativo, podemos ir directo o usar el mismo conversor para unificar
      for (String feedUrl in _feedUrls) {
        try {
          final apiUrl = 'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(feedUrl)}';
          var response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));

          // 🔄 MOTOR DE RESCATE MULTI-PROXY (Si rss2json falla)
          if (response.statusCode != 200 || response.body.contains('"status":"error"')) {
             debugPrint('⚠️ Rescate Nivel 1 activado para $feedUrl');
             
             // Intentar con Proxy 1: AllOrigins
             String? xml;
             try {
               final p1Url = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(feedUrl)}';
               final p1Res = await http.get(Uri.parse(p1Url)).timeout(const Duration(seconds: 10));
               if (p1Res.statusCode == 200) {
                 xml = json.decode(p1Res.body)['contents'];
               }
             } catch (e) {
               debugPrint('❌ Proxy 1 falló, intentando Proxy 2...');
             }

             // Intentar con Proxy 2: CodeTabs (Si el 1 falló)
             if (xml == null) {
               try {
                 final p2Url = 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(feedUrl)}';
                 final p2Res = await http.get(Uri.parse(p2Url)).timeout(const Duration(seconds: 10));
                 if (p2Res.statusCode == 200) {
                   xml = p2Res.body;
                 }
               } catch (e) {
                 debugPrint('❌ Proxy 2 también falló para $feedUrl');
               }
             }

             if (xml != null && xml.isNotEmpty) {
                final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
                final items = itemRegex.allMatches(xml);
                
                for (var match in items) {
                   final content = match.group(1)!;
                   final title = RegExp(r'<title>(.*?)</title>').firstMatch(content)?.group(1) ?? 'Noticia';
                   final link = RegExp(r'<link>(.*?)</link>').firstMatch(content)?.group(1) ?? '';
                   final desc = RegExp(r'<description>(.*?)</description>', dotAll: true).firstMatch(content)?.group(1) ?? '';
                   
                   String img = '';
                   final imgM = RegExp(r'''url=["']([^"']+\.(?:jpg|jpeg|png|webp))["']''').firstMatch(content);
                   if (imgM != null) img = imgM.group(1)!;
                   
                   _processItem(allArticles, {
                     'title': title,
                     'link': link,
                     'description': desc,
                     'thumbnail': img,
                     'content': desc,
                     'pubDate': RegExp(r'<pubDate>(.*?)</pubDate>').firstMatch(content)?.group(1) ?? '',
                   });
                }
                continue;
             }
          }

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == 'ok') {
              for (var item in data['items']) {
                _processItem(allArticles, item);
              }
            }
          }
        } catch (e) {
          debugPrint('Error cargando feed $feedUrl: $e');
        }
      }

      // Ordenar por fecha descendente
      allArticles.sort((a, b) => b.date.compareTo(a.date));

      state = NewsState(
        articles: allArticles,
        isLoading: false,
        error: allArticles.isEmpty
            ? 'No se pudieron cargar noticias. Inténtalo de nuevo más tarde.'
            : null,
      );
    } catch (e) {
      state = NewsState(
        articles: state.articles,
        isLoading: false,
        error: 'Error de red: $e',
      );
    }
  }

  void _processItem(List<NewsArticle> allArticles, Map<String, dynamic> item) {
    // 🕵️‍♂️ RADAR DE IMÁGENES DE ALTA PRECISIÓN (ESPECIAL SINC)
    String imageUrl = item['thumbnail'] ?? '';
    final String rawDescription = item['description'] ?? '';
    final String content = item['content'] ?? '';
    final String fullText = "$rawDescription $content";

    if (imageUrl.isEmpty || imageUrl.contains('unsplash.com')) {
      // 1. Buscar el patrón de almacenamiento interno de SINC (el más fiable)
      final sincPathRegex = RegExp(r'''(/[a-zA-Z0-9_/.-]+/storage/images/[^"']+\.(?:jpg|jpeg|png|webp))''', caseSensitive: false);
      final sincMatch = sincPathRegex.firstMatch(fullText);
      
      if (sincMatch != null) {
        imageUrl = sincMatch.group(1)!;
        if (imageUrl.startsWith('/')) {
          imageUrl = "https://www.agenciasinc.es$imageUrl";
        }
      } else {
        // 2. Fallback: Buscar cualquier etiqueta <img> estándar
        final imgRegex = RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false);
        final match = imgRegex.firstMatch(fullText);
        if (match != null) {
          imageUrl = match.group(1)!;
        }
      }
    }

    // 3. Normalizar URLs relativas
    if (imageUrl.startsWith('/')) {
      imageUrl = "https://www.agenciasinc.es$imageUrl";
    }

    if (imageUrl.isEmpty) {
      if (item['enclosure'] != null && item['enclosure']['link'] != null) {
        imageUrl = item['enclosure']['link'];
      }
    }

    // Fallback si sigue vacío
    if (imageUrl.isEmpty) {
      imageUrl = 'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?q=80&w=800&auto=format&fit=crop';
    }

    // 🛡️ PROXY DE IMAGENES PARA WEB (Weserv es súper estable para esto)
    if (kIsWeb && imageUrl.isNotEmpty && !imageUrl.contains('unsplash.com')) {
       imageUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(imageUrl)}&default=${Uri.encodeComponent('https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?q=80&w=800&auto=format&fit=crop')}';
    }

    // 🧼 LIMPIEZA DE DESCRIPCIÓN
    String description = rawDescription;
    description = description.replaceAll(RegExp(r'<[^>]*>'), ''); // Quitar HTML
    description = description.replaceAll('&nbsp;', ' ');
    description = description.replaceAll('&#8230;', '...');
    description = description.trim();

    if (description.length > 200) {
      description = '${description.substring(0, 197)}...';
    }

    allArticles.add(NewsArticle(
      title: item['title'] ?? 'Sin título',
      link: item['link'] ?? '',
      description: description,
      imageUrl: imageUrl,
      category: (item['categories'] as List?)?.isNotEmpty == true 
          ? item['categories'][0] 
          : 'Ciencia',
      date: DateTime.tryParse(item['pubDate'] ?? '') ?? DateTime.now(),
    ));
  }
}

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier();
});
