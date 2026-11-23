import 'dart:js_interop';

@JS('document.body.style')
external _Style get _bodyStyle;
@JS('document.documentElement.style')
external _Style get _rootStyle;

extension type _Style(JSObject _) implements JSObject {
  external String getPropertyValue(String name);
  external String getPropertyPriority(String name);
  external void setProperty(String name, String value, String priority);
  external String removeProperty(String name);
}

void Function() lockDocumentScroll() {
  final body = _bodyStyle;
  final root = _rootStyle;
  final oldOverflow = body.getPropertyValue('overflow');
  final oldPriority = body.getPropertyPriority('overflow');
  final oldGutter = root.getPropertyValue('scrollbar-gutter');
  final oldGutterPriority = root.getPropertyPriority('scrollbar-gutter');
  body.setProperty('overflow', 'hidden', '');
  root.setProperty('scrollbar-gutter', 'stable', '');
  var released = false;
  return () {
    if (released) return;
    released = true;
    if (oldOverflow.isEmpty) {
      body.removeProperty('overflow');
    } else {
      body.setProperty('overflow', oldOverflow, oldPriority);
    }
    if (oldGutter.isEmpty) {
      root.removeProperty('scrollbar-gutter');
    } else {
      root.setProperty('scrollbar-gutter', oldGutter, oldGutterPriority);
    }
  };
}
