import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/services/about_motion_preference.dart';
import 'technology_icon.dart';
import '../work/projects/project_deck_style.dart';

/// The expanded skills view: a vertical stack of small rectangular cards over
/// the blurred About page. On opening, one gentle highlight sweep runs from
/// the top card down to the bottom and back to the top; afterwards the panel
/// starts its inactivity countdown. Tapping a card repeats the same
/// lift-and-settle movement, and any interaction stops the sweep.
class SkillsCardStack extends StatefulWidget {
  final Map<String, List<String>> categories;
  final ScrollController controller;
  final VoidCallback onSweepComplete;

  const SkillsCardStack({
    super.key,
    required this.categories,
    required this.controller,
    required this.onSweepComplete,
  });

  @override
  State<SkillsCardStack> createState() => _SkillsCardStackState();
}

class _SkillsCardStackState extends State<SkillsCardStack> {
  static const _step = Duration(milliseconds: 300);
  Timer? _sweep;
  int? _lifted;

  // The panel lives in its own dialog route, outside the About subtree that
  // folds this preference into MediaQuery, so the web preference is read
  // directly here.
  final _motion = createAboutMotionPreference();

  bool get _reduced => _motion.value || MediaQuery.disableAnimationsOf(context);

  List<MapEntry<String, List<String>>> get _entries =>
      widget.categories.entries.toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  @override
  void dispose() {
    _sweep?.cancel();
    _motion.dispose();
    super.dispose();
  }

  void _stopSweep() {
    _sweep?.cancel();
    _sweep = null;
  }

  void _begin() {
    if (!mounted) return;
    final entries = _entries;
    if (entries.isEmpty) {
      widget.onSweepComplete();
      return;
    }
    if (_reduced) {
      // No movement under reduced motion; the idle countdown still starts.
      widget.onSweepComplete();
      return;
    }
    var index = 0;
    var climbing = false;
    void step() {
      if (!mounted || _sweep == null) return;
      if (!climbing) {
        setState(() => _lifted = index);
        if (index == entries.length - 1) {
          climbing = true;
          _sweep = Timer(_step, step);
          return;
        }
        index++;
        _sweep = Timer(_step, step);
      } else {
        if (index == 0) {
          _stopSweep();
          setState(() => _lifted = null);
          widget.onSweepComplete();
          return;
        }
        index--;
        setState(() => _lifted = index);
        _sweep = Timer(_step, step);
      }
    }

    _sweep = Timer(Duration.zero, step);
  }

  void _tap(int index) {
    _stopSweep();
    if (_reduced) return;
    setState(() => _lifted = index);
    Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() => _lifted = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reduced;
    final entries = _entries;
    return Listener(
      // Any touch or wheel on the stack pauses the automatic movement.
      onPointerDown: (_) => _stopSweep(),
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) _stopSweep();
      },
      child: SingleChildScrollView(
        controller: widget.controller,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _SkillsCard(
                heading: entries[i].key,
                skills: entries[i].value,
                lifted: _lifted == i,
                reduced: reduced,
                onTap: () => _tap(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  final String heading;
  final List<String> skills;
  final bool lifted;
  final bool reduced;
  final VoidCallback onTap;

  const _SkillsCard({
    required this.heading,
    required this.skills,
    required this.lifted,
    required this.reduced,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final duration =
        reduced ? Duration.zero : const Duration(milliseconds: 220);
    final skillsText =
        skills.map((skill) => skill.replaceAll(' - ', ' · ')).join(' · ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        duration: duration,
        curve: Curves.easeOutCubic,
        scale: lifted && !reduced ? 1.035 : 1,
        alignment: Alignment.topCenter,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: ProjectDeckStyle.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: lifted ? aboutAccent(t) : ProjectDeckStyle.hairline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: lifted ? .45 : .28),
                blurRadius: lifted ? 18 : 8,
                offset: Offset(0, lifted ? 8 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: aboutMono(t, size: 11, color: aboutAccent(t))),
              const SizedBox(height: 7),
              Text(skillsText, style: aboutMono(t, size: 12, color: t.text)),
            ],
          ),
        ),
      ),
    );
  }
}
