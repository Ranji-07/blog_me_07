import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('window.matchMedia')
external _MediaQueryList _matchMedia(String query);

extension type _MediaQueryList(JSObject _) implements JSObject {
  external bool get matches;
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

class _MotionPreference extends ValueNotifier<bool> {
  final _MediaQueryList _query;
  late final JSFunction _listener;
  _MotionPreference(this._query) : super(_query.matches) {
    _listener = ((JSAny? event) {
      value = _query.matches;
    }).toJS;
    _query.addEventListener('change', _listener);
  }
  @override
  void dispose() {
    _query.removeEventListener('change', _listener);
    super.dispose();
  }
}

ValueNotifier<bool> createMotionPreference() =>
    _MotionPreference(_matchMedia('(prefers-reduced-motion: reduce)'));
