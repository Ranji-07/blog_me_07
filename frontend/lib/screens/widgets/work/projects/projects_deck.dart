import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/services/about_motion_preference.dart';
import 'package:portfolio/services/about_scroll_lock.dart';
import 'project_artwork.dart';
import 'project_deck_style.dart';
import 'project_detail_sheet.dart';

class ProjectsDeck extends StatefulWidget {
  final List<Project> projects;
  final ValueChanged<bool>? onSheetVisibilityChanged;
  const ProjectsDeck(
      {super.key, required this.projects, this.onSheetVisibilityChanged});

  @override
  State<ProjectsDeck> createState() => _ProjectsDeckState();
}

class _ProjectsDeckState extends State<ProjectsDeck>
    with TickerProviderStateMixin {
  // Survives tab changes and responsive remounts during the app session.
  static final Set<int> _pulsedIds = {};
  // The swipe hint only needs to teach the gesture once per session.
  static bool _hintDismissed = false;
  final Set<String> _precached = {};
  final GlobalKey _stageKey = GlobalKey();
  late final PageController _pages;
  late final AnimationController _hint;
  late final AnimationController _tap;
  late final ValueNotifier<bool> _motion;
  ScrollPosition? _parentPosition;
  Timer? _settleTimer;
  Timer? _openTimer;
  ModalRoute<dynamic>? _sheetRoute;
  int _index = 0;
  int? _glowId;
  bool _moving = false;
  bool _opening = false;
  bool _sheetOpen = false;
  bool get _reduced => _motion.value || MediaQuery.disableAnimationsOf(context);
  double get _page => _pages.hasClients && _pages.position.hasContentDimensions
      ? (_pages.page ?? _index.toDouble())
      : _index.toDouble();

  @override
  void initState() {
    super.initState();
    _index = math.min(2, math.max(0, widget.projects.length - 1));
    _pages = PageController(viewportFraction: .62, initialPage: _index);
    _hint = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _tap = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _motion = createAboutMotionPreference()..addListener(_motionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedulePulse());
  }

  void _motionChanged() {
    if (!mounted) return;
    if (_reduced) _hint.reset();
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (position != _parentPosition) {
      _parentPosition?.isScrollingNotifier.removeListener(_parentScrollChanged);
      _parentPosition = position;
      position?.isScrollingNotifier.addListener(_parentScrollChanged);
    }
    for (final project in widget.projects) {
      final source = project.screenshot;
      if (source != null && _precached.add(source)) {
        final provider = projectImageProvider(source);
        if (provider != null) {
          precacheImage(provider, context, onError: (_, __) {});
        }
      }
    }
  }

  void _parentScrollChanged() {
    if (_parentPosition?.isScrollingNotifier.value ?? false) {
      _cancelInteraction();
    } else {
      _schedulePulse();
    }
  }

  bool get _visible {
    final box = _stageKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final y = box.localToGlobal(Offset.zero).dy;
    return y + 207 > 0 && y + 207 < MediaQuery.sizeOf(context).height;
  }

  void _schedulePulse() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted ||
          widget.projects.isEmpty ||
          _moving ||
          _opening ||
          _sheetOpen ||
          _reduced ||
          (_parentPosition?.isScrollingNotifier.value ?? false) ||
          !_visible ||
          (_page - _index).abs() > .02) {
        return;
      }
      final id = widget.projects[_index].id;
      if (!_pulsedIds.add(id)) return;
      setState(() => _glowId = id);
      _hint.forward(from: 0);
    });
  }

  void _cancelInteraction() {
    _settleTimer?.cancel();
    if (_sheetOpen) return;
    _openTimer?.cancel();
    _hint.reset();
    _tap.reset();
    if (mounted) {
      setState(() {
        _opening = false;
        _glowId = null;
      });
    }
  }

  void _select(int index) {
    if (_sheetOpen || _opening) return;
    if (index != _index || (_page - index).abs() > .08 || _moving) {
      _cancelInteraction();
      if (_reduced) {
        _pages.jumpToPage(index);
      } else {
        _pages.animateToPage(index,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
      return;
    }
    _settleTimer?.cancel();
    _hint.reset();
    setState(() {
      _opening = true;
      _glowId = widget.projects[index].id;
    });
    if (!_reduced) _tap.forward(from: 0);
    _openTimer = Timer(const Duration(milliseconds: 340), () {
      if (mounted && !_moving && _index == index) {
        _openSheet(widget.projects[index]);
      }
    });
  }

  Future<void> _openSheet(Project project) async {
    _sheetOpen = true;
    final visibilityChanged = widget.onSheetVisibilityChanged;
    final unlock = lockAboutDocumentScroll();
    visibilityChanged?.call(true);
    final reduced = _reduced;
    try {
      await showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          useSafeArea: true,
          isDismissible: true,
          enableDrag: true,
          showDragHandle: false,
          requestFocus: true,
          backgroundColor: ProjectDeckStyle.surface,
          barrierColor: Colors.black.withValues(alpha: .55),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          sheetAnimationStyle: reduced
              ? AnimationStyle.noAnimation
              : const AnimationStyle(
                  duration: Duration(milliseconds: 250),
                  reverseDuration: Duration(milliseconds: 250)),
          builder: (sheetContext) {
            _sheetRoute = ModalRoute.of(sheetContext);
            return ProjectDetailSheet(
                project: project,
                reducedMotion: reduced,
                onOpened: () {
                  if (!mounted) return;
                  _tap.reset();
                  _hintDismissed = true;
                  setState(() => _glowId = null);
                });
          });
      await _sheetRoute?.completed;
    } finally {
      _sheetRoute = null;
      unlock();
      visibilityChanged?.call(false);
      if (mounted) {
        setState(() {
          _opening = false;
          _sheetOpen = false;
          _glowId = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _openTimer?.cancel();
    _parentPosition?.isScrollingNotifier.removeListener(_parentScrollChanged);
    _motion.removeListener(_motionChanged);
    _motion.dispose();
    _hint.dispose();
    _tap.dispose();
    _pages.dispose();
    final route = _sheetRoute;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isCurrent) route.navigator?.pop();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) return const SizedBox.shrink();
    return ColoredBox(
      color: ProjectDeckStyle.background,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Semantics(
                header: true,
                child: Text('Projects',
                    style: ProjectDeckStyle.heading(size: 28)))),
        SizedBox(
            key: _stageKey,
            height: 414,
            child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth;
              final extent = width * .62;
              return AnimatedBuilder(
                  animation: Listenable.merge([_pages, _hint, _tap]),
                  builder: (context, _) {
                    final page = _page;
                    final order =
                        List.generate(widget.projects.length, (i) => i)
                          ..sort((a, b) =>
                              (b - page).abs().compareTo((a - page).abs()));
                    Rect cardRect(int i) {
                      final a = (i - page).abs().clamp(0.0, 1.6);
                      final scale = 1 - .15 * a;
                      return Rect.fromCenter(
                          center: Offset(width / 2 + (i - page) * extent, 207),
                          width: 220 * scale,
                          height: 310 * scale);
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        for (final i in order.reversed) {
                          if (cardRect(i).contains(details.localPosition)) {
                            _select(i);
                            break;
                          }
                        }
                      },
                      child: ClipRect(
                          child: Stack(children: [
                        Positioned.fill(
                            child: IgnorePointer(
                                child: ExcludeSemantics(
                                    child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final i in order)
                              if ((i - page).abs() < 2.6)
                                Positioned(
                                    left: width / 2 + (i - page) * extent - 110,
                                    top: 52,
                                    width: 220,
                                    height: 310,
                                    child: _visualCard(widget.projects[i],
                                        (i - page).abs().clamp(0.0, 1.6))),
                          ],
                        )))),
                        Positioned.fill(
                            child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.depth != 0 ||
                                notification.metrics.axis != Axis.horizontal) {
                              return false;
                            }
                            if (notification is ScrollStartNotification) {
                              _moving = true;
                              _cancelInteraction();
                            } else if (notification is ScrollEndNotification) {
                              _moving = false;
                              _schedulePulse();
                            }
                            return false;
                          },
                          child: ScrollConfiguration(
                              behavior: const MaterialScrollBehavior().copyWith(
                                  dragDevices: {
                                    PointerDeviceKind.touch,
                                    PointerDeviceKind.mouse,
                                    PointerDeviceKind.stylus
                                  }),
                              child: PageView.builder(
                                controller: _pages,
                                itemCount: widget.projects.length,
                                onPageChanged: (i) =>
                                    setState(() => _index = i),
                                itemBuilder: (context, i) =>
                                    FocusableActionDetector(
                                        shortcuts: const {
                                      SingleActivator(LogicalKeyboardKey.enter):
                                          ActivateIntent(),
                                      SingleActivator(LogicalKeyboardKey.space):
                                          ActivateIntent()
                                    },
                                        actions: {
                                      ActivateIntent:
                                          CallbackAction<ActivateIntent>(
                                              onInvoke: (_) {
                                        _select(i);
                                        return null;
                                      })
                                    },
                                        child: Semantics(
                                            button: true,
                                            selected: i == _index,
                                            label:
                                                '${widget.projects[i].title}, ${widget.projects[i].category}',
                                            hint: i == _index
                                                ? 'Double tap to open'
                                                : 'Move to centre',
                                            onTap: () => _select(i),
                                            child: const SizedBox.expand())),
                              )),
                        )),
                      ])),
                    );
                  });
            })),
        Text('${_index + 1} / ${widget.projects.length}',
            textAlign: TextAlign.center,
            style: ProjectDeckStyle.mono(color: ProjectDeckStyle.text)),
        if (!_hintDismissed) ...[
          const SizedBox(height: 8),
          Text('Swipe, then tap the centre card',
              textAlign: TextAlign.center, style: ProjectDeckStyle.mono()),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _visualCard(Project project, double a) {
    final centred = a < .08;
    double glow = 0;
    if (project.id == _glowId) {
      if (_opening) {
        glow = _reduced
            ? 0
            : (_tap.value < .38
                ? Curves.easeOut.transform(_tap.value / .38)
                : 1 - .65 * Curves.easeOut.transform((_tap.value - .38) / .62));
      } else {
        glow = math.sin(_hint.value * math.pi) * .5;
      }
    }
    final outlined = project.id == _glowId && (_opening || glow > .01);
    Widget card = Container(
        decoration: BoxDecoration(
            color: ProjectDeckStyle.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: outlined
                    ? ProjectDeckStyle.accent
                    : ProjectDeckStyle.hairline),
            boxShadow: glow > 0
                ? [
                    BoxShadow(
                        color: ProjectDeckStyle.accent
                            .withValues(alpha: .5 * glow),
                        blurRadius: 40,
                        spreadRadius: 8)
                  ]
                : []),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: ProjectArtwork(
                          screenshot: project.screenshot,
                          iconKey: project.iconKey,
                          centred: centred,
                          reducedMotion: _reduced)),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                      decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(
                                  color: ProjectDeckStyle.hairline))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(project.category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ProjectDeckStyle.mono(size: 11)
                                    .copyWith(letterSpacing: 1.5)),
                            const SizedBox(height: 6),
                            Text(project.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: ProjectDeckStyle.heading()),
                            const SizedBox(height: 8),
                            Text(project.stackLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ProjectDeckStyle.mono(size: 11)),
                          ])),
                ])));
    if (!centred) {
      card = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
              sigmaX: math.min(a, 1) * 3.4, sigmaY: math.min(a, 1) * 3.4),
          child: card);
    }
    return RepaintBoundary(
        child: Transform.scale(
            scale: 1 - .15 * a,
            child: Opacity(opacity: 1 - .38 * math.min(a, 1.2), child: card)));
  }
}
