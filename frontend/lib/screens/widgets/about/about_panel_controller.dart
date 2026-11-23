import 'dart:async';
import 'package:flutter/widgets.dart';

enum AboutPanelKind { biography, terminal }

/// One owner for About's modal state and end-of-reading countdown.
class AboutPanelController extends ChangeNotifier with WidgetsBindingObserver {
  AboutPanelController() {
    WidgetsBinding.instance.addObserver(this);
  }
  AboutPanelKind? active;
  final progress = ValueNotifier<double?>(null);
  bool keepOpen = false;
  bool accessibleNavigation = false;
  bool closing = false;
  double handoffDelta = 0;
  VoidCallback? requestClose;
  Timer? _settle;
  Timer? _countdown;
  bool _readInteraction = false;

  void begin(AboutPanelKind kind, {required bool accessible}) {
    cancelCountdown();
    active = kind;
    closing = false;
    handoffDelta = 0;
    keepOpen = false;
    accessibleNavigation = accessible;
    _readInteraction = false;
    notifyListeners();
  }

  void interact() {
    cancelCountdown();
  }

  void cancelCountdown() {
    _settle?.cancel();
    _countdown?.cancel();
    progress.value = null;
  }

  void setKeepOpen(bool value) {
    keepOpen = value;
    cancelCountdown();
    notifyListeners();
  }

  void observeScroll(ScrollNotification notification) {
    if (notification.depth != 0) return;
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      interact();
      _readInteraction = true;
    }
    if (notification is ScrollEndNotification && _readInteraction) {
      _readInteraction = false;
      if (notification.metrics.extentAfter <= 1) reachedEnd();
    }
  }

  void reachedEnd() {
    cancelCountdown();
    if (active == null || closing || keepOpen || accessibleNavigation) return;
    _settle = Timer(const Duration(milliseconds: 400), () {
      if (active == null || closing || keepOpen || accessibleNavigation) return;
      final clock = Stopwatch()..start();
      progress.value = 0;
      _countdown = Timer.periodic(const Duration(milliseconds: 40), (_) {
        progress.value = (clock.elapsedMilliseconds / 5000).clamp(0.0, 1.0);
        if (clock.elapsedMilliseconds >= 5000) close();
      });
    });
  }

  void close({double remainder = 0}) {
    handoffDelta = (handoffDelta + remainder).clamp(-1200.0, 1200.0);
    cancelCountdown();
    if (closing || active == null) return;
    closing = true;
    requestClose?.call();
  }

  void finish() {
    cancelCountdown();
    requestClose = null;
    active = null;
    closing = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) interact();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settle?.cancel();
    _countdown?.cancel();
    progress.dispose();
    super.dispose();
  }
}
