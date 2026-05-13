import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AiService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  final String _model = 'openai/gpt-oss-120b';

  // Catálogo cacheado en memoria para búsquedas locales rápidas
  Map<String, dynamic>? _catalogCache;
  // Índice compacto: solo nombres e IDs para el system prompt
  String? _catalogIndexCache;

  /// Carga el catálogo una sola vez y lo cachea en memoria
  Future<Map<String, dynamic>> _loadCatalog() async {
    if (_catalogCache != null) return _catalogCache!;
    final jsonStr = await rootBundle.loadString('assets/data/inventory/catalog_metadata.json');
    _catalogCache = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _catalogCache!;
  }

  /// Genera un índice compacto: "id -> nombre (sala)" para el system prompt
  Future<String> _buildCompactIndex() async {
    if (_catalogIndexCache != null) return _catalogIndexCache!;
    final catalog = await _loadCatalog();
    final buffer = StringBuffer();
    catalog.forEach((fileName, data) {
      final id = fileName.split('.').first.replaceAll(' ', '_');
      final name = data['name'] ?? id;
      final room = data['room'] ?? 'General';
      buffer.writeln('- $id: $name ($room)');
    });
    _catalogIndexCache = buffer.toString();
    return _catalogIndexCache!;
  }

  /// Busca localmente los detalles de una pieza por su ID
  Future<String> _getPieceDetails(String pieceId) async {
    final catalog = await _loadCatalog();
    // Búsqueda flexible: por ID exacto o por nombre de archivo parcial
    for (final entry in catalog.entries) {
      final id = entry.key.split('.').first.replaceAll(' ', '_');
      if (id.toLowerCase() == pieceId.toLowerCase() ||
          entry.key.toLowerCase().contains(pieceId.toLowerCase())) {
        final data = entry.value as Map<String, dynamic>;
        return jsonEncode({
          'id': id,
          'name': data['name'],
          'category': data['category'],
          'description': data['description'],
          'history': data['history'],
          'room': data['room'],
          'date': data['date'],
          'origin': data['origin'],
          'material': data['material'],
          'dimensions': data['dimensions'],
        });
      }
    }
    return jsonEncode({'error': 'Pieza no encontrada con ID: $pieceId'});
  }

  /// Definición de la herramienta para Groq Function Calling
  static const _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'get_piece_details',
        'description':
            'Obtiene los detalles completos de una pieza del museo: descripción, historia, material, sala, fecha y origen. Úsala cuando el visitante pregunte por una pieza específica.',
        'parameters': {
          'type': 'object',
          'properties': {
            'piece_id': {
              'type': 'string',
              'description':
                  'El ID de la pieza del museo (nombre del archivo sin extensión, con guiones bajos en lugar de espacios). Ejemplo: mandibula_hombre, Pez_globo_enano',
            }
          },
          'required': ['piece_id'],
        },
      },
    }
  ];

  Future<String> getChatResponse(List<ChatMessage> history) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'tu_api_key_aqui') {
      return 'Error: GROQ_API_KEY no configurada en env_config';
    }

    try {
      final compactIndex = await _buildCompactIndex();

      final systemMessage = {
        'role': 'system',
        'content': '''Eres el asistente inteligente del Museo Histórico Padre Suárez.
Ayuda a los visitantes con información sobre piezas, salas, la historia del museo y cómo usar la app.
Sé amable, culto y profesional. Responde en el idioma del visitante (español o inglés).

INFORMACIÓN DE LA APP:
- ENTRADAS: Se compran en la sección "Tienda" (icono carrito). Se elige la fecha, número de visitantes (General, Estudiante, Audioguía) y se paga con tarjeta mediante Stripe. Tras el pago se envía un QR al correo y queda guardado en "Mis Entradas".
- ACCESO AL MUSEO: En la puerta hay un escáner. El personal escanea el QR de tu entrada (desde la app en "Mis Entradas" o desde el correo).
- AR / REALIDAD AUMENTADA: En la pestaña con icono de cámara puedes escanear los QR físicos de las vitrinas para ver las piezas en 3D sobre el mundo real.
- VISITAS VIRTUALES 360°: En la sección Colección > Entornos puedes recorrer las salas del museo de forma inmersiva desde casa.
- SISTEMA DE RANGOS (Gamificación):
  * Visitante (0 piezas escaneadas) - Gris
  * Explorador (1-2 piezas) - Bronce
  * Académico (3-5 piezas) - Plata
  * Conservador Jefe (6+ piezas) - Oro
- FAVORITOS: Puedes marcar piezas con ♥ en la galería para guardarlas.
- BUSCADOR: En la Colección hay un campo de búsqueda para filtrar piezas por nombre o sala.
- MAPA INTERACTIVO: Muestra el plano del museo con las salas y sus piezas.
- IDIOMA: Cambiable en Ajustes (Español / English).
- DONACIONES: Disponibles en la sección Tienda.
- IMPRESIÓN 3D: Puedes solicitar réplicas físicas de las piezas 3D desde la galería.

SALAS DEL MUSEO:
- room_anatomy: Sala de Anatomía (mandíbulas, cráneos)
- room_zoology: Sala de Zoología/Biodiversidad (animales, corales)
- room_paleontology: Sala de Paleontología/Antropología (fósiles, evolución)
- room_physics: Laboratorio / Sala de Física e Instrumental
- room_archaeology: Sala de Mineralogía / Arqueología

LISTA DE PIEZAS DEL MUSEO (ID: nombre (sala)):
$compactIndex

INSTRUCCIONES:
- Si preguntan por una pieza específica, usa get_piece_details con su ID.
- Para preguntas sobre la app, responde directamente con la información de arriba.
- Mantén las respuestas concisas pero informativas.'''
      };

      // --- 1ª LLAMADA: con el índice compacto y las herramientas ---
      final firstResponse = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': [systemMessage, ...history.map((m) => m.toJson())],
          'tools': _tools,
          'tool_choice': 'auto',
          'temperature': 0.7,
          'max_tokens': 500,
        },
      );

      if (firstResponse.statusCode != 200) {
        return 'Error de conexión con el servidor de IA.';
      }

      final firstChoice = firstResponse.data['choices'][0];
      final finishReason = firstChoice['finish_reason'];

      // --- Si la IA ha decidido llamar a una herramienta ---
      if (finishReason == 'tool_calls') {
        final toolCalls = firstChoice['message']['tool_calls'] as List;
        final toolCall = toolCalls.first;
        final args = jsonDecode(toolCall['function']['arguments']) as Map<String, dynamic>;
        final pieceId = args['piece_id'] as String;

        // Búsqueda LOCAL (sin tokens extra)
        final pieceDetails = await _getPieceDetails(pieceId);

        // --- 2ª LLAMADA: con los detalles de la pieza encontrada ---
        final secondResponse = await _dio.post(
          _baseUrl,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
          ),
          data: {
            'model': _model,
            'messages': [
              systemMessage,
              ...history.map((m) => m.toJson()),
              firstChoice['message'], // mensaje de la IA con el tool_call
              {
                'role': 'tool',
                'tool_call_id': toolCall['id'],
                'content': pieceDetails,
              },
            ],
            'temperature': 0.7,
            'max_tokens': 500,
          },
        );

        if (secondResponse.statusCode == 200) {
          return secondResponse.data['choices'][0]['message']['content'];
        }
        return 'Error al procesar los detalles de la pieza.';
      }

      // --- Respuesta directa sin herramientas ---
      return firstChoice['message']['content'];
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        return '⏳ He recibido demasiadas preguntas seguidas. Espera unos segundos e inténtalo de nuevo.';
      }
      if (e.response?.statusCode == 413) {
        return 'El mensaje es demasiado largo. Intenta reformular la pregunta de forma más breve.';
      }
      return 'No he podido conectar con el servidor. Comprueba tu conexión e inténtalo de nuevo.';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }
}

final aiServiceProvider = Provider((ref) => AiService());

// ── Estado del Chat ──────────────────────────────────────────────────────────

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final AiService _aiService;

  ChatNotifier(this._aiService) : super(ChatState());

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: 'user', content: text);

    // Historial limitado a los últimos 5 mensajes (solo user/assistant)
    final currentHistory = [...state.messages, userMessage];
    final limitedHistory = currentHistory.length > 5
        ? currentHistory.sublist(currentHistory.length - 5)
        : currentHistory;

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    final responseContent = await _aiService.getChatResponse(limitedHistory);

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'assistant', content: responseContent)],
      isLoading: false,
    );
  }

  void clearChat() => state = ChatState();
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(aiServiceProvider));
});
