import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/journey_content.dart';
import 'package:portfolio/models/project.dart';
import 'package:portfolio/screens/widgets/work/work_timeline_section.dart';
import 'package:portfolio/screens/widgets/work/work_workspace_section.dart';
import 'package:portfolio/services/portfolio_api.dart';

/// The Work section has one data load and one visual sequence: timeline,
/// followed by the project/blog workspace. Keeping this composition here avoids
/// a second copy being mounted by a nested work widget.
class JourneyPage extends StatefulWidget {
  final Map<String, dynamic>? cachedContent;

  const JourneyPage({super.key, this.cachedContent});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  // The app shell owns one Work section. A hot-reload session can occasionally
  // retain a previous root view while creating a new one on web; only the first
  // mounted Work section is allowed to paint in that situation.
  static int? _renderOwner;
  late final int _instanceId;
  late final bool _ownsRenderSlot;
  late Future<_WorkPageContent> _contentFuture;

  @override
  void initState() {
    super.initState();
    _instanceId = identityHashCode(this);
    _ownsRenderSlot = _renderOwner == null;
    _renderOwner ??= _instanceId;
    _contentFuture = _load(widget.cachedContent);
  }

  @override
  void dispose() {
    if (_renderOwner == _instanceId) _renderOwner = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JourneyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cachedContent == null && widget.cachedContent != null) {
      setState(() => _contentFuture = _load(widget.cachedContent));
    }
  }

  Future<_WorkPageContent> _load(Map<String, dynamic>? cached) async {
    final content = cached ?? await PortfolioApi.fetchAll();
    final journeyRaw = content['journey'];
    final projectsRaw = content['projects'];
    final blogRaw = content['blog'];

    final journey = JourneyContent.fromJson(
      journeyRaw is Map<String, dynamic> ? journeyRaw : const {},
    );
    final projectsSection = projectsRaw is Map<String, dynamic>
        ? projectsRaw
        : const <String, dynamic>{};
    final projects = (projectsSection['projects'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Project.fromJson)
        .toList();
    final blogSection =
        blogRaw is Map<String, dynamic> ? blogRaw : const <String, dynamic>{};
    final blogEntries = (blogSection['entries'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BlogWorkspaceEntry.fromJson)
        .toList();

    return _WorkPageContent(
      journey: journey,
      projects: projects,
      blogEntries: blogEntries,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ownsRenderSlot) return const SizedBox.shrink();
    final t = AppTheme.of(context);
    final mobile = Responsive.isMobile(context);
    return Padding(
      // Clears the floating brand and navigation before the timeline begins.
      padding: EdgeInsets.fromLTRB(
        mobile ? AppSpacing.md : AppSpacing.xl,
        112,
        mobile ? AppSpacing.md : AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: FutureBuilder<_WorkPageContent>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text('Work content is unavailable.', style: t.body),
            );
          }
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final content = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorkTimelineSection(journey: content.journey),
              const SizedBox(height: AppSpacing.xl),
              WorkWorkspaceSection(
                projects: content.projects,
                blogEntries: content.blogEntries,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkPageContent {
  final JourneyContent journey;
  final List<Project> projects;
  final List<BlogWorkspaceEntry> blogEntries;

  const _WorkPageContent({
    required this.journey,
    required this.projects,
    required this.blogEntries,
  });
}
