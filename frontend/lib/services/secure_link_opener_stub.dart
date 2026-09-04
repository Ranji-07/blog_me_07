import 'package:url_launcher/url_launcher.dart';

Future<bool> openSecureExternalLink(String url) async {
  return launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
}
