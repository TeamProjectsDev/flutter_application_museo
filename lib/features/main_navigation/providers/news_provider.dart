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

      for (String feedUrl in _feedUrls) {
        try {
          final apiUrl = 'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(feedUrl)}';
          var response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 15));

          // 🔄 MATRIZ DE REDUNDANCIA QUÍNTUPLE 2026 (Blindaje Total)
          if (response.statusCode != 200 || response.body.contains('"status":"error"')) {
             debugPrint('⚠️ Rescate 2026 activado para $feedUrl');
             String? xml;
             
             // PROXY 1: BLOOPLE
             try {
               final p1Url = 'https://rss.bloople.net/?url=${Uri.encodeComponent(feedUrl)}&format=json';
               final p1Res = await http.get(Uri.parse(p1Url)).timeout(const Duration(seconds: 8));
               if (p1Res.statusCode == 200) {
                 final jsonRes = json.decode(p1Res.body);
                 for (var item in jsonRes) {
                   _processItem(allArticles, {
                     'title': item['title'],
                     'link': item['link'],
                     'description': item['description'],
                     'thumbnail': item['image_url'] ?? '',
                     'pubDate': item['pubDate'] ?? '',
                   });
                 }
                 continue; 
               }
             } catch (e) { debugPrint('❌ Bloople falló'); }

             // PROXY 2: CORS.LOL
             try {
               final p2Url = 'https://api.cors.lol/?url=${Uri.encodeComponent(feedUrl)}';
               final p2Res = await http.get(Uri.parse(p2Url)).timeout(const Duration(seconds: 8));
               if (p2Res.statusCode == 200) xml = p2Res.body;
             } catch (e) { debugPrint('❌ CORS.lol falló'); }

             // PROXY 3: COD ETABS
             if (xml == null) {
               try {
                 final p3Url = 'https://api.codetabs.com/v1/proxy?quest=${Uri.encodeComponent(feedUrl)}';
                 final p3Res = await http.get(Uri.parse(p3Url)).timeout(const Duration(seconds: 8));
                 if (p3Res.statusCode == 200) xml = p3Res.body;
               } catch (e) { debugPrint('❌ CodeTabs falló'); }
             }

             // PROXY 4: ALLORIGINS
             if (xml == null) {
               try {
                 final p4Url = 'https://api.allorigins.win/get?url=${Uri.encodeComponent(feedUrl)}';
                 final p4Res = await http.get(Uri.parse(p4Url)).timeout(const Duration(seconds: 8));
                 if (p4Res.statusCode == 200) xml = json.decode(p4Res.body)['contents'];
               } catch (e) { debugPrint('❌ AllOrigins falló'); }
             }

             // PROXY 5: THINGPROXY
             if (xml == null) {
               try {
                 final p5Url = 'https://thingproxy.freeboard.io/fetch/${Uri.encodeComponent(feedUrl)}';
                 final p5Res = await http.get(Uri.parse(p5Url)).timeout(const Duration(seconds: 8));
                 if (p5Res.statusCode == 200) xml = p5Res.body;
               } catch (e) { debugPrint('❌ ThingProxy falló'); }
             }

             if (xml != null && xml.isNotEmpty) {
                final itemRegex = RegExp(r'<item>(.*?)</item>', dotAll: true);
                final items = itemRegex.allMatches(xml);
                for (var match in items) {
                   final content = match.group(1)!;
                   String img = '';
                   final mediaMatch = RegExp(r'''<(?:media:content|media:thumbnail|enclosure)[^>]+url=["']([^"']+)["']''').firstMatch(content);
                   if (mediaMatch != null) img = mediaMatch.group(1)!;
                   
                   _processItem(allArticles, {
                     'title': RegExp(r'<title>(.*?)</title>').firstMatch(content)?.group(1) ?? 'Noticia',
                     'link': RegExp(r'<link>(.*?)</link>').firstMatch(content)?.group(1) ?? '',
                     'description': RegExp(r'<description>(.*?)</description>', dotAll: true).firstMatch(content)?.group(1) ?? '',
                     'thumbnail': img,
                     'content': content,
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

      allArticles.sort((a, b) => b.date.compareTo(a.date));
      state = NewsState(
        articles: allArticles,
        isLoading: false,
        error: allArticles.isEmpty ? 'No se pudieron cargar noticias.' : null,
      );
    } catch (e) {
      state = NewsState(articles: state.articles, isLoading: false, error: 'Error de red: $e');
    }
  }

  void _processItem(List<NewsArticle> allArticles, Map<String, dynamic> item) {
    String imageUrl = item['thumbnail'] ?? '';
    final String rawDescription = item['description'] ?? '';
    final String content = item['content'] ?? '';
    final String fullText = "$rawDescription $content";

    if (imageUrl.isEmpty || imageUrl.contains('unsplash.com') || imageUrl.length < 15) {
      final deepSearchRegex = RegExp(
        r'''(?:src|url|data-src|srcset)=["']([^"']+\.(?:jpg|jpeg|png|webp|avif)(?:\?[^"']+)?)["']''', 
        caseSensitive: false
      );
      final matches = deepSearchRegex.allMatches(fullText);
      for (var m in matches) {
        String foundUrl = m.group(1)!;
        if (!foundUrl.contains('logo') && !foundUrl.contains('icon') && !foundUrl.contains('tracker')) {
          imageUrl = foundUrl;
          break;
        }
      }
      if (imageUrl.isEmpty || imageUrl.contains('unsplash.com')) {
        final sincRegex = RegExp(r'''(/[a-zA-Z0-9_/.-]+/storage/images/[^"']+\.(?:jpg|jpeg|png|webp))''', caseSensitive: false);
        final sincMatch = sincRegex.firstMatch(fullText);
        if (sincMatch != null) imageUrl = sincMatch.group(1)!;
      }
    }

    if (imageUrl.startsWith('/')) imageUrl = "https://www.agenciasinc.es$imageUrl";
    if (imageUrl.isEmpty && item['enclosure'] != null) imageUrl = item['enclosure']['link'] ?? '';
    if (imageUrl.isEmpty) imageUrl = 'https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?q=80&w=800&auto=format&fit=crop';

    if (kIsWeb && imageUrl.isNotEmpty && !imageUrl.contains('unsplash.com')) {
       imageUrl = 'https://images.weserv.nl/?url=${Uri.encodeComponent(imageUrl)}&w=800&fit=cover&default=${Uri.encodeComponent('https://images.unsplash.com/photo-1566127444979-b3d2b654e3d7?q=80&w=800&auto=format&fit=crop')}';
    }

    String description = rawDescription;
    description = description.replaceAll(RegExp(r'<[^>]*>'), '');
    description = description.replaceAll('&nbsp;', ' ').replaceAll('&#8230;', '...').trim();
    if (description.length > 200) description = '${description.substring(0, 197)}...';

    allArticles.add(NewsArticle(
      title: item['title'] ?? 'Sin título',
      link: item['link'] ?? '',
      description: description,
      imageUrl: imageUrl,
      category: (item['categories'] as List?)?.isNotEmpty == true ? item['categories'][0] : 'Ciencia',
      date: DateTime.tryParse(item['pubDate'] ?? '') ?? DateTime.now(),
    ));
  }
}

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier();
});
