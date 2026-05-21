import 'external_url_launcher_stub.dart'
    if (dart.library.html) 'external_url_launcher_web.dart'
    if (dart.library.io) 'external_url_launcher_io.dart'
    as launcher_impl;

Future<bool> openExternalUrl(Uri uri) {
  return launcher_impl.openExternalUrl(uri);
}
