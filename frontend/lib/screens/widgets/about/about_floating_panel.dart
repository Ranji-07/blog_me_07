import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'about_panel_controller.dart';
import 'technology_icon.dart';
import '../work/projects/project_deck_style.dart';

/// Keep a hit-testable barrier during the return flight. Flutter's standard
/// barrier ignores reverse-transition input, which would lose fast wheel bursts
/// while the background is intentionally still locked.
class _AboutDialogRoute extends RawDialogRoute<void> {
  final AboutPanelController panelController;
  _AboutDialogRoute(
      {required this.panelController,
      required super.pageBuilder,
      required super.transitionBuilder,
      required super.transitionDuration})
      : super(
            barrierDismissible: true,
            barrierLabel: 'Close About panel',
            barrierColor: Colors.transparent,
            requestFocus: true,
            traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  @override
  Widget buildModalBarrier() => Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (event) {
          if (panelController.closing &&
              panelController.active == AboutPanelKind.terminal &&
              event is PointerScrollEvent) {
            panelController.close(remainder: event.scrollDelta.dy);
          }
        },
        child: ModalBarrier(
            color: Colors.transparent,
            dismissible: true,
            semanticsLabel: 'Dismiss About backdrop',
            onDismiss: panelController.close),
      );
}

Future<void> showAboutPanel({
  required BuildContext context,
  required AboutPanelController controller,
  required ScrollController scroll,
  required Widget content,
  Rect? Function()? sourceRect,
  bool Function()? prefersReducedMotion,
}) async {
  final terminal = controller.active == AboutPanelKind.terminal;
  final initialReduced = MediaQuery.disableAnimationsOf(context) ||
      (prefersReducedMotion?.call() ?? false);
  final route = _AboutDialogRoute(
    panelController: controller,
    transitionDuration:
        initialReduced ? Duration.zero : const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, _, __) {
      controller.requestClose = () {
        if (dialogContext.mounted && ModalRoute.of(dialogContext)!.isCurrent) {
          Navigator.of(dialogContext).pop();
        }
      };
      return AboutFloatingPanel(
          controller: controller,
          scroll: scroll,
          terminal: terminal,
          content: content);
    },
    transitionBuilder: (context, animation, _, child) => LayoutBuilder(
      builder: (context, constraints) {
        final reduced = MediaQuery.disableAnimationsOf(context) ||
            (prefersReducedMotion?.call() ?? false);
        final size = constraints.biggest;
        final mobile = size.width < 600;
        final bottom = 12 + MediaQuery.paddingOf(context).bottom;
        final width = math.min(760.0, size.width - 24);
        final height = math.min(
            620.0,
            size.height -
                MediaQuery.viewInsetsOf(context).bottom -
                84 -
                bottom);
        final destination = Rect.fromLTWH(
            (size.width - width) / 2,
            mobile
                ? size.height -
                    height -
                    bottom -
                    MediaQuery.viewInsetsOf(context).bottom
                : (size.height - height) / 2,
            width,
            height);
        final progress =
            reduced ? 1.0 : Curves.easeOut.transform(animation.value);
        final source = terminal ? sourceRect?.call() : null;
        final rect = source != null && !reduced
            ? Rect.lerp(source, destination, progress)!
            : destination.shift(
                Offset(0, reduced ? 0 : (mobile ? 24 : 10) * (1 - progress)));
        return Stack(children: [
          Positioned.fill(
              child: IgnorePointer(
                  child: BackdropFilter(
            filter:
                ImageFilter.blur(sigmaX: 6 * progress, sigmaY: 6 * progress),
            child: ColoredBox(
                color: Colors.black
                    .withValues(alpha: (terminal ? .55 : .76) * progress)),
          ))),
          Positioned.fromRect(
              rect: rect,
              child: Opacity(
                  opacity: reduced ? 1 : animation.value,
                  child: ClipRect(child: child))),
        ]);
      },
    ),
  );
  await Navigator.of(context, rootNavigator: true).push(route);
  // push() resolves at the start of dismissal; keep locks until return flight ends.
  await route.completed;
}

class AboutFloatingPanel extends StatefulWidget {
  final AboutPanelController controller;
  final ScrollController scroll;
  final bool terminal;
  final Widget content;
  const AboutFloatingPanel(
      {super.key,
      required this.controller,
      required this.scroll,
      required this.terminal,
      required this.content});
  @override
  State<AboutFloatingPanel> createState() => _AboutFloatingPanelState();
}

class _AboutFloatingPanelState extends State<AboutFloatingPanel> {
  double _pull = 0;
  AboutPanelController get panel => widget.controller;

  void _pointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !widget.scroll.hasClients) return;
    panel.interact();
    final position = widget.scroll.position;
    final delta = event.scrollDelta.dy;
    final consumed = (position.pixels + delta)
            .clamp(position.minScrollExtent, position.maxScrollExtent) -
        position.pixels;
    final remainder = delta - consumed;
    if (widget.terminal && remainder.abs() > .5) {
      // The inner Scrollable consumes its portion. Handoff only its remainder
      // after this event, keeping the background locked during the flight back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) panel.close(remainder: remainder);
      });
    } else if (position.extentAfter <= 1 && delta > 0) {
      panel.reachedEnd();
    }
  }

  void _endKey() {
    panel.interact();
    if (widget.scroll.hasClients) {
      widget.scroll.jumpTo(widget.scroll.position.maxScrollExtent);
      panel.reachedEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Semantics(
      role: SemanticsRole.dialog,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: widget.terminal ? 'Skills inventory dialog' : 'About me dialog',
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): panel.close,
          const SingleActivator(LogicalKeyboardKey.end): _endKey,
        },
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                event.logicalKey != LogicalKeyboardKey.end) {
              panel.interact();
            }
            return KeyEventResult.ignored;
          },
          onFocusChange: (_) => panel.interact(),
          child: Listener(
            onPointerDown: (_) => panel.interact(),
            onPointerMove: (_) => panel.interact(),
            onPointerSignal: _pointerSignal,
            child: Material(
              color: widget.terminal ? t.card : Colors.transparent,
              elevation: widget.terminal ? 20 : 0,
              shape: widget.terminal
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: t.border))
                  : null,
              clipBehavior: Clip.antiAlias,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (mobile)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: (_) {
                          _pull = 0;
                          panel.interact();
                        },
                        onVerticalDragUpdate: (event) {
                          _pull += event.delta.dy;
                          if (_pull > 72) panel.close();
                        },
                        child: Semantics(
                            label: 'Drag down to close panel',
                            child: SizedBox(
                                height: 28,
                                width: double.infinity,
                                child: Center(
                                    child: Container(
                                        width: 40,
                                        height: 4,
                                        decoration: BoxDecoration(
                                            color: t.textMuted,
                                            borderRadius:
                                                BorderRadius.circular(4)))))),
                      ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                        // Biography chrome sits over the dark scrim in both
                        // theme modes, so it uses the fixed dark tokens.
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  widget.terminal
                                      ? '~/portfolio/skills'
                                      : 'About me',
                                  style: widget.terminal
                                      ? aboutMono(t, size: 14, color: t.text)
                                      : t.subheading.copyWith(
                                          color: ProjectDeckStyle.text))),
                          if (!widget.terminal)
                            ListenableBuilder(
                                listenable: panel,
                                builder: (_, __) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                              semanticLabel: 'Keep open',
                                              value: panel.keepOpen,
                                              activeColor: AppColors.button,
                                              side: const BorderSide(
                                                  color:
                                                      ProjectDeckStyle.muted),
                                              onChanged: (value) => panel
                                                  .setKeepOpen(value ?? false)),
                                          Text('Keep open',
                                              style: aboutMono(t,
                                                  color:
                                                      ProjectDeckStyle.text)),
                                        ])),
                          IconButton(
                              autofocus: true,
                              tooltip: 'Close About panel',
                              onPressed: panel.close,
                              icon: Icon(Icons.close_rounded,
                                  color: widget.terminal
                                      ? t.text
                                      : ProjectDeckStyle.text)),
                        ])),
                    if (widget.terminal) Divider(height: 1, color: t.border),
                    Expanded(
                        child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        panel.observeScroll(notification);
                        if (notification is OverscrollNotification &&
                            notification.dragDetails != null) {
                          if (widget.terminal &&
                              notification.overscroll.abs() > 1) {
                            _pull += notification.overscroll;
                            if (_pull.abs() > 72) panel.close(remainder: _pull);
                          } else if (mobile &&
                              notification.metrics.pixels <= 0 &&
                              notification.overscroll < 0) {
                            _pull -= notification.overscroll;
                            if (_pull > 96) panel.close();
                          }
                        }
                        if (notification is ScrollStartNotification) _pull = 0;
                        return false;
                      },
                      child: widget.content,
                    )),
                    if (widget.terminal) Divider(height: 1, color: t.border),
                    if (widget.terminal)
                      ListenableBuilder(
                          listenable: panel,
                          builder: (_, __) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: Row(children: [
                                  Expanded(
                                      child: CheckboxListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: aboutAccent(t),
                                    title:
                                        Text('Keep open', style: aboutMono(t)),
                                    value: panel.keepOpen,
                                    onChanged: (value) =>
                                        panel.setKeepOpen(value ?? false),
                                  )),
                                  TextButton(
                                      style: TextButton.styleFrom(
                                          foregroundColor: aboutAccent(t)),
                                      onPressed: panel.close,
                                      child: const Text('Close')),
                                ]),
                              )),
                    ValueListenableBuilder<double?>(
                        valueListenable: panel.progress,
                        builder: (_, value, __) => Semantics(
                              label: value == null
                                  ? 'Auto-close inactive'
                                  : 'Closes after five seconds of inactivity; interact or choose Keep open to cancel',
                              child: SizedBox(
                                  height: 3,
                                  child: value == null
                                      ? const SizedBox.expand()
                                      : ExcludeSemantics(
                                          child: LinearProgressIndicator(
                                              value: value,
                                              color: aboutAccent(t),
                                              backgroundColor: t.border))),
                            )),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
