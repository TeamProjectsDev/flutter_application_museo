import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  static const String _apiUrl = 'https://api.stripe.com/v1/checkout/sessions';

  /// Crea una nueva Checkout Session en Stripe y devuelve la URL para redirigir al usuario.
  Future<String?> createCheckoutSession({
    required String productName,
    required int amountInCents, // Ej: 1500 = 15.00€
    required String currency, // Ej: 'eur'
    required String successUrl,
    required String cancelUrl,
  }) async {
    final secretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';

    if (secretKey.isEmpty) {
      throw Exception('STRIPE_SECRET_KEY no configurado en .env');
    }

    final headers = {
      'Authorization': 'Bearer $secretKey',
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    // Construimos el body simulando Form URL-Encoded según las reglas de Stripe API
    final body = {
      'payment_method_types[0]': 'card',
      'line_items[0][price_data][currency]': currency,
      'line_items[0][price_data][product_data][name]': productName,
      'line_items[0][price_data][unit_amount]': amountInCents.toString(),
      'line_items[0][quantity]': '1',
      'mode': 'payment',
      'success_url': successUrl,
      'cancel_url': cancelUrl,
    };

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['url']
            as String?; // Devolvemos la URL del Checkout dinámico
      } else {
        throw Exception(
          'Error Stripe: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
