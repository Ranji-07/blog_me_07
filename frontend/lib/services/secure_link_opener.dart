import 'secure_link_opener_stub.dart'
    if (dart.library.html) 'secure_link_opener_web.dart' as impl;

Future<bool> openSecureExternalLink(String url) {
  return impl.openSecureExternalLink(url);
}
