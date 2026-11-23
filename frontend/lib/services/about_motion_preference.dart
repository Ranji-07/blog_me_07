import 'package:flutter/widgets.dart';
import 'about_motion_preference_stub.dart'
    if (dart.library.js_interop) 'about_motion_preference_web.dart' as platform;

ValueNotifier<bool> createAboutMotionPreference() =>
    platform.createMotionPreference();

/// Synchronous reduced-motion check for one-shot decisions such as opening a
/// dialog or starting a scroll: combines the platform setting exposed through
/// [MediaQuery] with the web `prefers-reduced-motion` preference. Widgets that
/// must keep watching the preference should use [createAboutMotionPreference].
bool prefersReducedMotion(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return true;
  final preference = createAboutMotionPreference();
  final value = preference.value;
  preference.dispose();
  return value;
}
