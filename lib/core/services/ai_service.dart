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

  /// Carga el catálogo una sola vez y lo cachea en memoria
  Future<Map<String, dynamic>> _loadCatalog() async {
    if (_catalogCache != null) return _catalogCache!;
    final jsonStr = await rootBundle.loadString('assets/data/inventory/catalog_metadata.json');
    _catalogCache = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _catalogCache!;
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

  /// Herramientas quirúrgicas para ahorrar tokens
  static const _tools = [
    {
      'type': 'function',
      'function': {
        'name': 'search_catalog',
        'description': 'Busca piezas por nombre o palabras clave. Devuelve IDs y nombres.',
        'parameters': {
          'type': 'object',
          'properties': {
            'query': {'type': 'string', 'description': 'Término de búsqueda (ej: "cráneo", "coral")'}
          },
          'required': ['query'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_room_inventory',
        'description': 'Lista todas las piezas de una sala específica.',
        'parameters': {
          'type': 'object',
          'properties': {
            'room_id': {'type': 'string', 'enum': ['room_anatomy', 'room_zoology', 'room_paleontology', 'room_physics', 'room_archaeology']}
          },
          'required': ['room_id'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_inventory_by_type',
        'description': 'Lista piezas filtrando por tipo (3D o 360).',
        'parameters': {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'enum': ['3D', '360']}
          },
          'required': ['type'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'get_piece_details',
        'description': 'Obtiene detalles completos de una pieza específica usando su ID.',
        'parameters': {
          'type': 'object',
          'properties': {
            'piece_id': {'type': 'string', 'description': 'ID de la pieza (ej: mandibula_hombre)'}
          },
          'required': ['piece_id'],
        },
      },
    }
  ];

  Future<String> _handleToolCall(String name, Map<String, dynamic> args) async {
    final catalog = await _loadCatalog();
    switch (name) {
      case 'search_catalog':
        final query = (args['query'] as String).toLowerCase();
        final results = catalog.entries
            .where((e) => e.key.toLowerCase().contains(query) || (e.value['name'] as String).toLowerCase().contains(query))
            .map((e) => '- ${e.key.split('.').first}: ${e.value['name']}')
            .join('\n');
        return results.isEmpty ? 'No hay resultados.' : 'Resultados:\n$results';

      case 'get_room_inventory':
        final roomId = args['room_id'];
        final results = catalog.entries
            .where((e) => e.value['room'] == roomId)
            .map((e) => '- ${e.key.split('.').first}: ${e.value['name']}')
            .join('\n');
        return 'Inventario de la sala:\n$results';

      case 'get_inventory_by_type':
        final is3DRequested = args['type'] == '3D';
        final results = catalog.entries
            .where((e) => e.key.toLowerCase().endsWith(is3DRequested ? '.glb' : '.jpg'))
            .map((e) => '- ${e.key.split('.').first}: ${e.value['name']}')
            .join('\n');
        return 'Inventario por tipo:\n$results';

      case 'get_piece_details':
        return await _getPieceDetails(args['piece_id']);
        
      default:
        return 'Error: Herramienta no implementada.';
    }
  }

  Future<String> getChatResponse(List<ChatMessage> history) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return 'Error: API Key faltante.';

    try {
      final catalog = await _loadCatalog();
      int count3D = catalog.keys.where((k) => k.toLowerCase().endsWith('.glb')).length;
      int count360 = catalog.keys.where((k) => k.toLowerCase().endsWith('.jpg')).length;

      final systemMessage = {
        'role': 'system',
        'content': '''Eres el guía virtual del Museo Padre Suárez. 
RESUMEN DE COLECCIÓN: $count3D modelos 3D y $count360 entornos 360°.
SALAS: room_anatomy, room_zoology, room_paleontology, room_physics, room_archaeology.

INSTRUCCIONES DE TOKENS:
- NO inventes piezas.
- Si preguntan por una sala, usa get_room_inventory.
- Si preguntan por tipo, usa get_inventory_by_type.
- Si preguntan por algo genérico, usa search_catalog.
- Una vez tengas el ID de lo que le interesa al usuario, usa get_piece_details para darle la historia completa.
- Responde de forma breve y profesional.'''
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
        final functionName = toolCall['function']['name'];
        final args = jsonDecode(toolCall['function']['arguments']) as Map<String, dynamic>;

        // Ejecutar la herramienta solicitada
        final toolResult = await _handleToolCall(functionName, args);

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
                'content': toolResult,
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
