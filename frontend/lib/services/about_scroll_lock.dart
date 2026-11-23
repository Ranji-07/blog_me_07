import 'about_scroll_lock_stub.dart'
    if (dart.library.js_interop) 'about_scroll_lock_web.dart' as platform;

void Function() lockAboutDocumentScroll() => platform.lockDocumentScroll();
