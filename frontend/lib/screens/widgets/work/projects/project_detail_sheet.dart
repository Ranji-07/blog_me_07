import 'package:flutter/material.dart';
import 'package:portfolio/models/project.dart';
import 'project_artwork.dart';
import 'project_deck_style.dart';

class ProjectDetailSheet extends StatefulWidget {
  final Project project;
  final bool reducedMotion;
  final VoidCallback onOpened;
  const ProjectDetailSheet(
      {super.key,
      required this.project,
      required this.reducedMotion,
      required this.onOpened});

  @override
  State<ProjectDetailSheet> createState() => _ProjectDetailSheetState();
}

class _ProjectDetailSheetState extends State<ProjectDetailSheet> {
  Animation<double>? _animation;
  bool _announced = false;

  void _status(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_announced) {
      _announced = true;
      widget.onOpened();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = ModalRoute.of(context)?.animation;
    if (next != _animation) {
      _animation?.removeStatusListener(_status);
      _animation = next;
      next?.addStatusListener(_status);
      if (next?.isCompleted ?? true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _status(AnimationStatus.completed);
        });
      }
    }
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_status);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return DraggableScrollableSheet(
      initialChildSize: .9,
      minChildSize: .35,
      maxChildSize: .9,
      expand: false,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: ColoredBox(
          color: ProjectDeckStyle.surface,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(children: [
                  Container(
                      width: 34,
                      height: 4,
                      decoration: BoxDecoration(
                          color: ProjectDeckStyle.muted,
                          borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 18),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(project.category.toUpperCase(),
                              style: ProjectDeckStyle.mono()
                                  .copyWith(letterSpacing: 1.5)),
                          const SizedBox(height: 6),
                          Semantics(
                              header: true,
                              child: Text(project.title,
                                  style: ProjectDeckStyle.heading(size: 24))),
                        ])),
                    const SizedBox(width: 12),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            foregroundColor: ProjectDeckStyle.text,
                            backgroundColor: ProjectDeckStyle.raised,
                            shape: const StadiumBorder(
                                side: BorderSide(
                                    color: ProjectDeckStyle.hairline))),
                        child: Text('Close ✕',
                            style: ProjectDeckStyle.mono(
                                color: ProjectDeckStyle.text))),
                  ]),
                ])),
            Expanded(
                child: SingleChildScrollView(
                    controller: scrollController,
                    child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    height: 190,
                                    width: double.infinity,
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: ProjectArtwork(
                                            screenshot: project.screenshot,
                                            iconKey: project.iconKey,
                                            centred: true,
                                            reducedMotion:
                                                widget.reducedMotion))),
                                const SizedBox(height: 22),
                                Text(project.summary,
                                    style: ProjectDeckStyle.body()),
                                const SizedBox(height: 26),
                                Text('What it does',
                                    style: ProjectDeckStyle.heading(size: 18)),
                                const SizedBox(height: 12),
                                for (final bullet in project.bullets.take(3))
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Padding(
                                                padding: EdgeInsets.only(
                                                    top: 8, right: 12),
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                        color: ProjectDeckStyle
                                                            .accent,
                                                        shape: BoxShape.circle),
                                                    child: SizedBox.square(
                                                        dimension: 5))),
                                            Expanded(
                                                child: Text(bullet,
                                                    style: ProjectDeckStyle
                                                        .body())),
                                          ])),
                                const SizedBox(height: 14),
                                Text('Built with',
                                    style: ProjectDeckStyle.heading(size: 18)),
                                const SizedBox(height: 12),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  for (final technology in project.stack)
                                    ProjectStackChip(technology: technology),
                                ]),
                              ]),
                        )))),
          ]),
        ),
      ),
    );
  }
}

/// A single "Built with" chip, shared by the mobile detail sheet and the
/// desktop project dialog so both render identically.
class ProjectStackChip extends StatelessWidget {
  final String technology;
  const ProjectStackChip({super.key, required this.technology});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: ProjectDeckStyle.raised,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: ProjectDeckStyle.hairline)),
      child: Text(technology,
          style: ProjectDeckStyle.mono(color: ProjectDeckStyle.text)),
    );
  }
}
