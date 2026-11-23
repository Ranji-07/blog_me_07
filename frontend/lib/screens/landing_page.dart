import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/common/loading/section_skeletons.dart';
import 'package:portfolio/common/loading/shimmer_box.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/about_motion_preference.dart';
import 'package:portfolio/services/portfolio_api.dart';
import 'package:portfolio/common/social/social_links.dart';
import 'package:portfolio/screens/resume_dialog.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onEnter;
  final VoidCallback onProjects;
  final ValueChanged<Map<String, dynamic>> onPortfolioContentLoaded;
  final ValueListenable<double> scrollProgress;

  const LandingScreen({
    super.key,
    required this.onEnter,
    required this.onProjects,
    required this.onPortfolioContentLoaded,
    required this.scrollProgress,
  });

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static bool _hasPlayedIntroThisSession = false;
  final _motion = createAboutMotionPreference();
  _LandingContent? _content;
  String? _error;
  Timer? _typewriterTimer;
  int _roleIndex = 0;
  int _visibleCharacters = 0;
  bool _isDeleting = false;
  bool _animateIntro = false;

  bool get _reduced => _motion.value || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _motion.addListener(_motionChanged);
    _loadContent();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _motion.removeListener(_motionChanged);
    _motion.dispose();
    super.dispose();
  }

  void _motionChanged() {
    if (!mounted) return;
    if (_motion.value) _freezeTypewriter();
    setState(() {});
  }

  /// Reduced motion must land on a complete role, never mid-word.
  void _freezeTypewriter() {
    _typewriterTimer?.cancel();
    final roles = _content?.displayRoles ?? const <String>[];
    if (roles.isEmpty) return;
    _roleIndex = _roleIndex.clamp(0, roles.length - 1);
    _visibleCharacters = roles[_roleIndex].length;
  }

  Future<void> _loadContent() async {
    try {
      final decoded = await PortfolioApi.fetchAll();
      if (!mounted) {
        return;
      }
      widget.onPortfolioContentLoaded(decoded);
      final reduced = _reduced;
      _animateIntro = !reduced && !_hasPlayedIntroThisSession;
      _hasPlayedIntroThisSession = true;
      final content = _LandingContent.fromJson(decoded);
      if (reduced) {
        // Present the first role complete, without typing or cycling.
        _roleIndex = 0;
        final roles = content.displayRoles;
        _visibleCharacters = roles.isEmpty ? 0 : roles.first.length;
      }
      setState(() => _content = content);
      if (!reduced) _startTypewriter(withIntroDelay: _animateIntro);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load portfolio details.');
      }
    }
  }

  void _startTypewriter({required bool withIntroDelay}) {
    _typewriterTimer?.cancel();
    final roles = _content?.displayRoles ?? const <String>[];
    if (roles.isEmpty) {
      return;
    }
    _roleIndex = 0;
    _visibleCharacters = 0;
    _isDeleting = false;
    if (withIntroDelay) {
      _typewriterTimer = Timer(
        const Duration(milliseconds: 780),
        _scheduleTypewriterTick,
      );
    } else {
      _scheduleTypewriterTick();
    }
  }

  void _scheduleTypewriterTick() {
    final roles = _content?.displayRoles ?? const <String>[];
    if (!mounted || roles.isEmpty) {
      return;
    }
    final role = roles[_roleIndex];
    Duration delay = const Duration(milliseconds: 72);

    if (!_isDeleting && _visibleCharacters < role.length) {
      _visibleCharacters++;
    } else if (!_isDeleting) {
      if (roles.length == 1) {
        return;
      }
      _isDeleting = true;
      delay = const Duration(milliseconds: 1250);
    } else if (_visibleCharacters > 0) {
      _visibleCharacters--;
      delay = const Duration(milliseconds: 42);
    } else {
      _roleIndex = (_roleIndex + 1) % roles.length;
      _isDeleting = false;
      delay = const Duration(milliseconds: 380);
    }

    setState(() {});
    _typewriterTimer = Timer(delay, _scheduleTypewriterTick);
  }

  void _explorePortfolio() {
    unawaited(_trackVisit());
    widget.onEnter();
  }

  Future<void> _trackVisit() async {
    try {
      await PortfolioApi.recordVisit();
    } catch (_) {
      // Analytics must never prevent navigation.
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.background, t.surface, t.background],
        ),
      ),
      child: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _error != null
              ? _LandingError(message: _error!, onRetry: _loadContent)
              : _content == null
                  ? const _LandingSkeleton()
                  : _LandingLayout(
                      content: _content!,
                      roleIndex: _roleIndex,
                      visibleCharacters: _visibleCharacters,
                      animateIntro: _animateIntro,
                      reducedMotion: _reduced,
                      scrollProgress: widget.scrollProgress,
                      onExplore: _explorePortfolio,
                      onProjects: widget.onProjects,
                    ),
        ),
      ),
    );
  }
}

class _LandingLayout extends StatelessWidget {
  final _LandingContent content;
  final int roleIndex;
  final int visibleCharacters;
  final bool animateIntro;
  final bool reducedMotion;
  final ValueListenable<double> scrollProgress;
  final VoidCallback onExplore;
  final VoidCallback onProjects;

  const _LandingLayout({
    required this.content,
    required this.roleIndex,
    required this.visibleCharacters,
    required this.animateIntro,
    required this.reducedMotion,
    required this.scrollProgress,
    required this.onExplore,
    required this.onProjects,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final horizontal = isMobile ? 20.0 : 34.0;
    final headerHorizontal =
        isMobile && MediaQuery.sizeOf(context).width < 380 ? 12.0 : horizontal;
    final displayRoles = content.displayRoles;
    final currentRole = displayRoles.isEmpty ? '' : displayRoles[roleIndex];
    final visibleRole = currentRole.substring(
      0,
      visibleCharacters.clamp(0, currentRole.length),
    );
    final roleFontSize = (content.roleFontSize ?? 32)
        .clamp(isMobile ? 28 : 40, isMobile ? 36 : 58)
        .toDouble();

    return Stack(
      key: const ValueKey('landing-content'),
      children: [
        ValueListenableBuilder<double>(
          valueListenable: scrollProgress,
          builder: (context, progress, _) => Positioned.fill(
            child: Transform.translate(
              offset: Offset(0, -28 * progress),
              child: Opacity(
                opacity: 1 - (progress * .30),
                child: _HeroBackground(
                  imageAsset: content.heroBackgroundAsset,
                  imageUrl: _absoluteImageUrl(content.heroBackgroundUrl),
                  animateIntro: animateIntro,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: isMobile ? 12 : 24,
          left: headerHorizontal,
          child: _LandingEntrance(
            animate: animateIntro,
            start: .24,
            end: .43,
            offsetY: 12,
            child: _IdentityBlock(
              name: content.name,
              avatarUrl: _absoluteImageUrl(content.avatarUrl),
              fontFamily: content.nameFontFamily ?? 'Outfit',
              fontSize: ((content.nameFontSize ?? 20) + (isMobile ? 2 : 3))
                  .clamp(18, 30)
                  .toDouble(),
              fontWeight:
                  (content.nameFontWeight ?? 600).clamp(100, 900).toDouble(),
            ),
          ),
        ),
        Positioned(
          top: isMobile ? 18 : 24,
          right: headerHorizontal,
          child: _LandingEntrance(
            animate: animateIntro,
            start: .24,
            end: .43,
            offsetY: 12,
            child: _StatusResume(availability: content.availability),
          ),
        ),
        ValueListenableBuilder<double>(
          valueListenable: scrollProgress,
          builder: (context, progress, _) => Align(
            alignment:
                Alignment(isMobile ? -0.78 : -0.7, isMobile ? -0.08 : -0.12),
            child: Transform.translate(
              offset: Offset(0, -16 * progress),
              child: Opacity(
                opacity: 1 - (progress * .46),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isMobile ? 400 : 630),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LandingEntrance(
                          animate: animateIntro,
                          start: .33,
                          end: .60,
                          offsetY: 12,
                          child: Text(
                            "Hello, I'm a",
                            style: t.subheading.copyWith(
                              color: t.textMuted,
                              fontSize: isMobile ? 19 : 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _LandingEntrance(
                          animate: animateIntro,
                          start: .52,
                          end: .72,
                          offsetY: 10,
                          child: SizedBox(
                            // Fixed two-line box: the role may type and wrap
                            // freely inside it, but the introduction line
                            // above can never shift.
                            height: roleFontSize * 2.3,
                            child: RichText(
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              text: TextSpan(
                                style: t.display.copyWith(
                                  fontSize: roleFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: t.text,
                                  height: 1.04,
                                ),
                                children: [
                                  TextSpan(text: visibleRole),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: _TypewriterCursor(
                                      fontSize: roleFontSize,
                                      animate: !reducedMotion,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (content.valueStatement.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Text(
                              content.valueStatement,
                              textAlign: TextAlign.start,
                              style: t.body.copyWith(
                                fontSize: isMobile ? 15 : 17,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: isMobile ? horizontal : 34,
          right: isMobile ? horizontal : null,
          // Social icons sit close to the bottom edge, clear of the device's
          // gesture/navigation area; the buttons follow 10px above them.
          bottom: isMobile ? 12 + MediaQuery.paddingOf(context).bottom : 28,
          child: _LandingEntrance(
            animate: animateIntro,
            start: .78,
            end: 1,
            offsetY: 10,
            child: ContactLinksSection(
              email: content.email,
              githubUrl: content.githubUrl,
              linkedinUrl: content.linkedinUrl,
              spacing: 20,
            ),
          ),
        ),
        Positioned(
          right: horizontal,
          left: isMobile ? horizontal : null,
          bottom: isMobile
              ? 12 + MediaQuery.paddingOf(context).bottom + 56 + 10
              : 28,
          child: _LandingEntrance(
            animate: animateIntro,
            start: .66,
            end: .86,
            offsetY: 12,
            child: isMobile
                ? Row(
                    children: [
                      Expanded(
                        child: _LandingButton(
                          label: 'Explore Portfolio',
                          outlined: true,
                          compact: true,
                          onPressed: onExplore,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LandingButton(
                          label: 'View Projects',
                          icon: Icons.arrow_forward_rounded,
                          outlined: true,
                          compact: true,
                          onPressed: onProjects,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LandingButton(
                        label: 'Explore Portfolio',
                        outlined: true,
                        onPressed: onExplore,
                      ),
                      const SizedBox(width: 16),
                      _LandingButton(
                        label: 'View Projects',
                        icon: Icons.arrow_forward_rounded,
                        outlined: true,
                        onPressed: onProjects,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String? _absoluteImageUrl(String value) {
    if (value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme ? uri.toString() : null;
  }
}

class HeroImageConfig {
  HeroImageConfig._();

  /// Override with `--dart-define=HERO_BACKGROUND_ASSET=assets/your-image.png`.
  static const String defaultBackgroundAsset = String.fromEnvironment(
    'HERO_BACKGROUND_ASSET',
    defaultValue: 'assets/hero_portrait.png',
  );
}

class _HeroBackground extends StatelessWidget {
  final String imageAsset;
  final String? imageUrl;
  final bool animateIntro;

  const _HeroBackground({
    required this.imageAsset,
    required this.imageUrl,
    required this.animateIntro,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final image = imageUrl == null
        ? Image.asset(
            imageAsset.trim().isEmpty
                ? HeroImageConfig.defaultBackgroundAsset
                : imageAsset,
            fit: BoxFit.cover,
            // A missing configured asset falls back to the default hero,
            // mirroring the network image failure path.
            errorBuilder: (_, __, ___) => Image.asset(
              HeroImageConfig.defaultBackgroundAsset,
              fit: BoxFit.cover,
            ),
          )
        : Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              HeroImageConfig.defaultBackgroundAsset,
              fit: BoxFit.cover,
            ),
          );
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        duration:
            animateIntro ? const Duration(milliseconds: 650) : Duration.zero,
        tween: Tween(begin: animateIntro ? 0.0 : 1.0, end: 1),
        builder: (context, progress, child) => Opacity(
          opacity: progress,
          child: Transform.scale(
            scale: 1.03 - (.03 * Curves.easeOutCubic.transform(progress)),
            child: child,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: t.background),
            Positioned.fill(
              child: Align(
                alignment: isMobile
                    ? const Alignment(0.52, -0.08)
                    : Alignment.centerRight,
                child: SizedBox.expand(child: image),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.96),
                    Colors.black.withValues(alpha: isMobile ? 0.62 : 0.18),
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  stops: const [0, 0.56, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingEntrance extends StatefulWidget {
  final bool animate;
  final double start;
  final double end;
  final double offsetY;
  final Widget child;

  const _LandingEntrance({
    required this.animate,
    required this.start,
    required this.end,
    required this.offsetY,
    required this.child,
  });

  @override
  State<_LandingEntrance> createState() => _LandingEntranceState();
}

class _LandingEntranceState extends State<_LandingEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      value: widget.animate ? 0 : 1,
    );
    if (widget.animate) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _LandingEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(widget.start, widget.end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.offsetY / 100),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

class _TypewriterCursor extends StatefulWidget {
  final double fontSize;
  final bool animate;

  const _TypewriterCursor({required this.fontSize, required this.animate});

  @override
  State<_TypewriterCursor> createState() => _TypewriterCursorState();
}

class _TypewriterCursorState extends State<_TypewriterCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _TypewriterCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && oldWidget.animate) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Text(
        '|',
        style: AppTheme.of(context).display.copyWith(
              color: AppTheme.of(context).button,
              fontSize: widget.fontSize * 0.88,
              height: 1.04,
            ),
      );
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 0.2, end: 1).animate(_controller),
      child: Text(
        '|',
        style: AppTheme.of(context).display.copyWith(
              color: AppTheme.of(context).button,
              fontSize: widget.fontSize * 0.88,
              height: 1.04,
            ),
      ),
    );
  }
}

class _IdentityBlock extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final String fontFamily;
  final double fontSize;
  final double fontWeight;

  const _IdentityBlock({
    required this.name,
    required this.avatarUrl,
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
  });

  @override
  State<_IdentityBlock> createState() => _IdentityBlockState();
}

class _IdentityBlockState extends State<_IdentityBlock> {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final avatarSize = isMobile ? 32.0 : 42.0;
    final initials = widget.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.button.withValues(alpha: .82)),
          ),
          child: ClipOval(
            child: SizedBox(
              width: avatarSize,
              height: avatarSize,
              child: widget.avatarUrl == null
                  ? Image.asset(
                      'assets/WhatsApp Image 2025-05-20 at 09.54.48_af8a40f8.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarFallback(initials: initials),
                    )
                  : Image.network(
                      widget.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/WhatsApp Image 2025-05-20 at 09.54.48_af8a40f8.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _AvatarFallback(initials: initials),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.name,
          style: t.subheading.copyWith(
            fontFamily: widget.fontFamily,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.lerp(
              FontWeight.w100,
              FontWeight.w900,
              (widget.fontWeight - 100) / 800,
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.of(context).button,
      child: Center(
        child: Text(
          initials.isEmpty ? 'VP' : initials,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatusResume extends StatefulWidget {
  final String availability;

  const _StatusResume({required this.availability});

  @override
  State<_StatusResume> createState() => _StatusResumeState();
}

class _StatusResumeState extends State<_StatusResume>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final _motion = createAboutMotionPreference();
  Timer? _resumeTimer;
  Timer? _pulseTimer;
  bool _resumeDone = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // One gentle pulse every 2 seconds; the guard below keeps the dot
    // completely static when reduced motion is preferred.
    _pulseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted &&
          !_motion.value &&
          !MediaQuery.disableAnimationsOf(context)) {
        _pulse.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _pulseTimer?.cancel();
    _resumeTimer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  void _showResume() {
    ResumePreviewDialog.show(context, onActionComplete: () {
      _resumeTimer?.cancel();
      setState(() => _resumeDone = true);
      _resumeTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _resumeDone = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final (color, label) = switch (widget.availability) {
      'freelance' => (t.button, 'Available for Freelance'),
      'unavailable' => (AppColors.danger, 'Not Available'),
      _ => (AppColors.success, 'Open to Work'),
    };
    final mobile = Responsive.isMobile(context);
    final narrowMobile = mobile && MediaQuery.sizeOf(context).width < 380;
    final dotSize = mobile ? 8.0 : 10.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: label,
          child: FadeTransition(
            opacity: TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 1.0, end: .55), weight: 45),
              TweenSequenceItem(tween: Tween(begin: .55, end: 1.0), weight: 55),
            ]).animate(_pulse),
            child: ScaleTransition(
              scale: TweenSequence<double>([
                TweenSequenceItem(
                    tween: Tween(begin: 1.0, end: 1.14), weight: 45),
                TweenSequenceItem(
                    tween: Tween(begin: 1.14, end: 1.0), weight: 55),
              ]).animate(_pulse),
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: t.label.copyWith(
            color: t.text,
            fontSize: narrowMobile ? 12 : (mobile ? 13 : 15),
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            height: 1.3,
          ),
        ),
        SizedBox(width: mobile ? 12 : 16),
        Tooltip(
          message: 'View Resume',
          child: InkWell(
            onTap: _showResume,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: mobile ? 20 : 22,
              height: mobile ? 24 : 26,
              child: _resumeDone
                  ? Icon(Icons.check_rounded, size: 19, color: color)
                  : Icon(
                      Icons.article_outlined,
                      size: mobile ? 21 : 23,
                      color: t.text,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LandingButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool outlined;
  final bool compact;
  final FutureOr<void> Function() onPressed;

  const _LandingButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.compact = false,
  });

  @override
  State<_LandingButton> createState() => _LandingButtonState();
}

class _LandingButtonState extends State<_LandingButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final buttonHeight = widget.compact ? 44.0 : 48.0;
    final buttonWidth = widget.compact ? 0.0 : 176.0;
    void onPressed() {
      Future.sync(widget.onPressed);
    }

    final button = widget.outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: widget.icon == null
                ? const SizedBox.shrink()
                : AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    offset: _hovered ? const Offset(0.16, 0) : Offset.zero,
                    child: Icon(widget.icon, size: 19),
                  ),
            label: Text(
              widget.label,
              // Buttons keep the sans body face; mono is reserved for labels
              // so the compact CTAs still fit at 360px widths.
              style: t.label.copyWith(
                fontFamily: GoogleFonts.inter().fontFamily,
                fontSize: widget.compact ? 16 : 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.text,
              side: BorderSide(color: _hovered ? t.button : t.border),
              minimumSize: Size(buttonWidth, buttonHeight),
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8 : 14,
              ),
              shape: const StadiumBorder(),
            ),
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: t.button,
              foregroundColor: Colors.white,
              minimumSize: Size(buttonWidth, buttonHeight),
            ),
            child: Text(widget.label),
          );
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: t.button.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  )
                ]
              : const [],
        ),
        child: button,
      ),
    );
  }
}

class _LandingSkeleton extends StatelessWidget {
  const _LandingSkeleton();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final horizontal = isMobile ? 20.0 : 34.0;
    return SectionSkeleton(builder: (context, shimmer) {
      ShimmerBox box(double width, double height,
              {bool circle = false, double radius = AppRadius.sm}) =>
          ShimmerBox(
            width: width,
            height: height,
            circle: circle,
            radius: radius,
            animation: shimmer,
          );
      return Stack(
        key: const ValueKey('landing-skeleton'),
        children: [
          Positioned(
            top: isMobile ? 18 : 26,
            left: horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                box(44, 44, circle: true),
                const SizedBox(width: 12),
                box(160, 22),
              ],
            ),
          ),
          Positioned(
            top: isMobile ? 72 : 26,
            left: isMobile ? horizontal : null,
            right: isMobile ? null : horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                box(10, 10, circle: true),
                const SizedBox(width: 8),
                box(100, 18),
                const SizedBox(width: 20),
                box(24, 24, radius: AppRadius.sm),
              ],
            ),
          ),
          Positioned(
            top: isMobile ? 220 : 250,
            left: horizontal,
            right: horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                box(280, 36),
                const SizedBox(height: 18),
                box(300, 16),
                const SizedBox(height: 8),
                box(240, 16),
              ],
            ),
          ),
          Positioned(
            left: isMobile ? horizontal : 34,
            right: isMobile ? horizontal : null,
            bottom: isMobile ? 20 : 28,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                box(32, 32, circle: true),
                const SizedBox(width: 20),
                box(32, 32, circle: true),
                const SizedBox(width: 20),
                box(32, 32, circle: true),
              ],
            ),
          ),
          Positioned(
            right: horizontal,
            left: isMobile ? horizontal : null,
            bottom: isMobile ? 92 : 28,
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                box(180, 52, radius: AppRadius.full),
                box(180, 52, radius: AppRadius.full),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _LandingError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LandingError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: t.body.copyWith(color: t.text)),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _LandingContent {
  final String name;
  final String title;
  final List<String> roles;
  final String availability;
  final String? nameFontFamily;
  final double? nameFontSize;
  final int? nameFontWeight;
  final double? roleFontSize;
  final String avatarUrl;
  final String portraitUrl;
  final String heroBackgroundUrl;
  final String heroBackgroundAsset;
  final String valueStatement;
  final String email;
  final String githubUrl;
  final String linkedinUrl;

  const _LandingContent({
    required this.name,
    required this.title,
    required this.roles,
    required this.availability,
    required this.nameFontFamily,
    required this.nameFontSize,
    required this.nameFontWeight,
    required this.roleFontSize,
    required this.avatarUrl,
    required this.portraitUrl,
    required this.heroBackgroundUrl,
    required this.heroBackgroundAsset,
    required this.valueStatement,
    required this.email,
    required this.githubUrl,
    required this.linkedinUrl,
  });

  List<String> get displayRoles => roles.isNotEmpty
      ? roles
      : title.trim().isEmpty
          ? const []
          : [title];

  factory _LandingContent.fromJson(Map<String, dynamic> json) {
    final about = (json['about'] as Map<String, dynamic>?) ?? const {};
    final contact = (json['contact'] as Map<String, dynamic>?) ?? const {};
    final social = (contact['social'] as Map<String, dynamic>?) ?? const {};
    final roles = (about['roles'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .where((role) => role.trim().isNotEmpty)
        .toList();
    return _LandingContent(
      name: (about['name'] as String?) ?? 'Portfolio',
      title: (about['title'] as String?) ?? '',
      roles: roles,
      availability: (about['availability'] as String?) ?? 'open',
      nameFontFamily: about['name_font_family'] as String?,
      nameFontSize: (about['name_font_size'] as num?)?.toDouble(),
      nameFontWeight: about['name_font_weight'] as int?,
      roleFontSize: (about['role_font_size'] as num?)?.toDouble(),
      avatarUrl: (about['avatar_url'] as String?) ?? '',
      portraitUrl: (about['portrait_url'] as String?) ?? '',
      heroBackgroundUrl: (about['hero_background_url'] as String?) ??
          (about['portrait_url'] as String?) ??
          '',
      heroBackgroundAsset: (about['hero_background_asset'] as String?) ?? '',
      valueStatement: (about['value_statement'] as String?) ?? '',
      email: (contact['email'] as String?) ?? '',
      githubUrl: (social['github'] as String?) ?? '',
      linkedinUrl: (social['linkedin'] as String?) ?? '',
    );
  }
}
