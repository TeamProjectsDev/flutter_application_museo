import 'package:web/web.dart' as web;

/// Redirige a una URL externa. 
/// En la Web, forzamos el cambio en la misma pestaña.
Future<void> redirectToUrl(String url) async {
  web.window.location.href = url;
}
