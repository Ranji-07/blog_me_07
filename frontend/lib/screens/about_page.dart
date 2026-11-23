import 'package:flutter/material.dart';
import 'package:portfolio/common/loading/section_skeletons.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/models/about_profile.dart';
import 'package:portfolio/services/portfolio_api.dart';
import 'package:portfolio/services/about_scroll_lock.dart';
import 'package:portfolio/services/about_motion_preference.dart';
import 'widgets/about/about_panel_controller.dart';
import 'widgets/about/about_floating_panel.dart';
import 'widgets/about/core_stack_honeycomb.dart';
import 'widgets/about/skills_terminal.dart';
import 'widgets/about/technology_feeder.dart';
import 'widgets/about/technology_icon.dart';
import 'widgets/work/projects/project_deck_style.dart';

class AboutScreen extends StatefulWidget {
  final Map<String, dynamic>? cachedContent;
  final ValueChanged<bool>? onPanelVisibilityChanged;
  final ValueChanged<double>? onPageScrollHandoff;
  const AboutScreen(
      {super.key,
      this.cachedContent,
      this.onPanelVisibilityChanged,
      this.onPageScrollHandoff});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _panel = AboutPanelController();
  final _motionPreference = createAboutMotionPreference();
  final _terminalScroll = SkillsScrollController();
  final _terminalSlot = GlobalKey();
  final _biographyFocus = FocusNode(debugLabel: 'Read more about me');
  final _terminalFocus = FocusNode(debugLabel: 'Expand skills terminal');
  final _allSkillsFocus = FocusNode(debugLabel: 'View all skills');
  final _headingFocus = FocusNode(debugLabel: 'About heading');
  late final Future<AboutProfile> _profile = _load();
  Future<void>? _panelDone;
  int _request = 0;

  Future<AboutProfile> _load() async {
    final cached = widget.cachedContent?['about'];
    return AboutProfile.fromJson(cached is Map<String, dynamic>
        ? cached
        : await PortfolioApi.fetchAbout());
  }

  Rect? _sourceRect() {
    final box = _terminalSlot.currentContext?.findRenderObject() as RenderBox?;
    return box == null || !box.attached || !box.hasSize
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _open(
      AboutPanelKind kind, AboutProfile profile, FocusNode trigger) async {
    final request = ++_request;
    if (_panel.active != null) {
      _panel.close();
      await _panelDone;
      if (!mounted || request != _request) return;
    }
    _panel.begin(kind, accessible: MediaQuery.of(context).accessibleNavigation);
    widget.onPanelVisibilityChanged?.call(true);
    void Function()? unlock;
    final biographyScroll =
        kind == AboutPanelKind.biography ? ScrollController() : null;
    try {
      unlock = lockAboutDocumentScroll();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final scroll = biographyScroll ?? _terminalScroll;
      final content = kind == AboutPanelKind.terminal
          ? SkillsInventory(
              categories: profile.skillCategories, controller: scroll)
          : Scrollbar(
              controller: scroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(24),
                child: SelectionArea(
                    onSelectionChanged: (_) => _panel.interact(),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Biography content always sits over the dark scrim,
                          // so it uses the fixed dark-surface text tokens.
                          for (final paragraph in profile.aboutMe)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text(paragraph,
                                    style: AppTheme.of(context).body.copyWith(
                                        fontSize: 17,
                                        height: 1.75,
                                        color: ProjectDeckStyle.text))),
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: _panel.close,
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.button),
                                  child: const Text('Read less'))),
                        ])),
              ));
      _panelDone = showAboutPanel(
          context: context,
          controller: _panel,
          scroll: scroll,
          content: content,
          prefersReducedMotion: () => _motionPreference.value,
          sourceRect: kind == AboutPanelKind.terminal ? _sourceRect : null);
      await _panelDone;
    } finally {
      unlock?.call();
      biographyScroll?.dispose();
      if (mounted) {
        final delta = _panel.handoffDelta;
        _panel.finish();
        widget.onPanelVisibilityChanged?.call(false);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) {
          if (delta.abs() > .5) {
            widget.onPageScrollHandoff?.call(delta);
          } else {
            (trigger.context != null ? trigger : _headingFocus).requestFocus();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _request++;
    _panel.dispose();
    _motionPreference.dispose();
    _terminalScroll.dispose();
    _biographyFocus.dispose();
    _terminalFocus.dispose();
    _allSkillsFocus.dispose();
    _headingFocus.dispose();
    super.dispose();
  }

  Widget _story(AboutProfile profile, bool mobile, {required int lineLimit}) {
    final t = AppTheme.of(context);
    final technologies = aboutTechnologies(profile.skillCategories);
    final core = technologies
        .where((technology) => technology.logoAsset != null)
        .toList()
      ..sort((a, b) {
        final ai = aboutCoreNames.indexOf(a.canonicalName);
        final bi = aboutCoreNames.indexOf(b.canonicalName);
        if (ai >= 0 || bi >= 0) {
          return (ai < 0 ? aboutCoreNames.length : ai)
              .compareTo(bi < 0 ? aboutCoreNames.length : bi);
        }
        return 0;
      });
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Focus(
          focusNode: _headingFocus,
          child: Semantics(
              header: true,
              child: Text('A Little About Me',
                  style: t.heading.copyWith(
                      color: aboutAccent(t), fontSize: mobile ? 28 : null)))),
      const SizedBox(height: 14),
      Text(
          profile.aboutMe.isEmpty
              ? 'Engineering practical systems from development to deployment.'
              : profile.aboutMe.first,
          maxLines: lineLimit,
          overflow: TextOverflow.ellipsis,
          style: t.body.copyWith(fontSize: mobile ? 15 : 17)),
      Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: TextButton.styleFrom(foregroundColor: aboutAccent(t)),
            focusNode: _biographyFocus,
            onPressed: () =>
                _open(AboutPanelKind.biography, profile, _biographyFocus),
            child: const Text('Read more ↗'),
          )),
      if (!mobile) ...[
        const SizedBox(height: 28),
        Text('Core stack', style: t.subheading),
        const SizedBox(height: 18),
        Wrap(spacing: 14, runSpacing: 18, children: [
          for (final technology in core)
            Semantics(
                label: technology.name,
                child: SizedBox(
                    width: 80,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TechnologyIcon(
                          technology: technology,
                          size: 38,
                          removeServiceBackground: true),
                      const SizedBox(height: 6),
                      Text(technology.canonicalName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: aboutMono(t, size: 11, color: t.text)),
                    ]))),
        ]),
      ],
    ]);
  }

  Widget _terminal(AboutProfile profile) {
    final t = AppTheme.of(context);
    return SizedBox(
      key: _terminalSlot,
      height: (MediaQuery.sizeOf(context).height - 200).clamp(420.0, 720.0),
      child: _panel.active == AboutPanelKind.terminal
          ? DecoratedBox(
              decoration: BoxDecoration(
                  color: t.card,
                  border: Border.all(color: t.border),
                  borderRadius: BorderRadius.circular(16)),
              child: Center(
                  child: Text('Skills inventory is open', style: aboutMono(t))))
          : SkillsTerminal(
              categories: profile.skillCategories,
              controller: _terminalScroll,
              expandFocus: _terminalFocus,
              onExpand: () =>
                  _open(AboutPanelKind.terminal, profile, _terminalFocus)),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: _motionPreference,
        builder: (context, reduced, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations:
                  MediaQuery.disableAnimationsOf(context) || reduced),
          child: Builder(builder: _buildContent),
        ),
      );

  Widget _buildContent(BuildContext context) => FutureBuilder<AboutProfile>(
        future: _profile,
        builder: (context, snapshot) {
          final t = AppTheme.of(context);
          if (snapshot.hasError) {
            return Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Unable to load profile details right now.',
                    style: t.body));
          }
          if (!snapshot.hasData) {
            return const AboutSectionSkeleton();
          }
          final profile = snapshot.data!;
          return ListenableBuilder(
              listenable: _panel,
              builder: (context, _) => ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.sizeOf(context).height),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
                        MediaQuery.sizeOf(context).width < 600 ? 96 : 112,
                        MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
                        MediaQuery.sizeOf(context).width < 600 ? 24 : 48),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final mobile = constraints.maxWidth < 600;
                      if (constraints.maxWidth >= 960) {
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 5,
                                  child: _story(profile, false, lineLimit: 5)),
                              const SizedBox(width: 40),
                              Expanded(flex: 7, child: _terminal(profile)),
                            ]);
                      }
                      final technologies =
                          aboutTechnologies(profile.skillCategories);
                      final core = aboutCoreNames
                          .map((name) => technologies
                              .where((t) => t.canonicalName == name))
                          .expand((t) => t)
                          .toList();
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _story(profile, mobile,
                                lineLimit: mobile ? 3 : 4),
                            SizedBox(height: mobile ? 16 : 28),
                            if (!mobile)
                              _terminal(profile)
                            else ...[
                              CoreStackHoneycomb(technologies: core),
                              Text('Also familiar with', style: aboutMono(t)),
                              const SizedBox(height: 8),
                              TechnologyFeeder(
                                  technologies: technologies
                                      .where((tech) =>
                                          tech.logoAsset != null &&
                                          !aboutCoreNames
                                              .contains(tech.canonicalName))
                                      .toList(),
                                  paused: _panel.active != null),
                              TextButton.icon(
                                  style: TextButton.styleFrom(
                                      foregroundColor: aboutAccent(t)),
                                  focusNode: _allSkillsFocus,
                                  onPressed: () => _open(
                                      AboutPanelKind.terminal,
                                      profile,
                                      _allSkillsFocus),
                                  icon: const Icon(Icons.terminal_rounded,
                                      size: 18),
                                  label: const Text('View all skills')),
                            ],
                          ]);
                    }),
                  )));
        },
      );
}
