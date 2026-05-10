import 'package:url_launcher/url_launcher_string.dart';

/// Redirige a una URL externa. 
/// En Móviles, usa el lanzador estándar del sistema.
Future<void> redirectToUrl(String url) async {
  await launchUrlString(url, mode: LaunchMode.externalApplication);
}
