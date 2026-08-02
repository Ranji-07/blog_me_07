import 'package:flutter/material.dart';

/// Centralized Animation System
/// Provides consistent motion design inspired by Apple/Stripe interfaces

// ─────────────────────────── Global Animation Constants ──────────────────────
class AppAnimations {
  AppAnimations._();

  // Duration tokens (Apple-style timing)
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 450);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration slower = Duration(milliseconds: 800);
  static const Duration slowest = Duration(milliseconds: 1000);

  // Entrance animation durations
  static const Duration entranceFade = Duration(milliseconds: 500);
  static const Duration entranceSlide = Duration(milliseconds: 600);
  static const Duration entranceScale = Duration(milliseconds: 400);

  // Modal animation durations
  static const Duration modalEnter = Duration(milliseconds: 350);
  static const Duration modalExit = Duration(milliseconds: 280);

  // Stagger delay for sequential animations
  static const Duration staggerDelay = Duration(milliseconds: 80);
  static const Duration staggerDelayFast = Duration(milliseconds: 50);
  static const Duration staggerDelaySlow = Duration(milliseconds: 120);

  // Floating animation duration
  static const Duration floatCycle = Duration(seconds: 3);
}

// ─────────────────────────── Custom Curves (Apple-inspired) ──────────────────
class AppCurves {
  AppCurves._();

  // Standard easing curves
  static const Curve ease = Curves.easeInOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;

  // Apple-style cubic curves
  static const Curve appleEase = Cubic(0.25, 0.1, 0.25, 1.0);
  static const Curve appleEaseIn = Cubic(0.42, 0.0, 1.0, 1.0);
  static const Curve appleEaseOut = Cubic(0.0, 0.0, 0.58, 1.0);
  static const Curve appleEaseInOut = Cubic(0.42, 0.0, 0.58, 1.0);

  // Spring-like curves for natural motion
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.0);
  static const Curve springSmooth = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve springBounce = Cubic(0.68, -0.55, 0.265, 1.55);

  // Modal specific curves
  static const Curve modalEnter = Cubic(0.32, 0.72, 0.0, 1.0);
  static const Curve modalExit = Cubic(0.4, 0.0, 0.2, 1.0);

  // Smooth deceleration for entrance animations
  static const Curve decelerate = Curves.decelerate;
  static const Curve smoothDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  // Elastic curves for playful interactions
  static const Curve elastic = ElasticOutCurve(0.8);
  static const Curve elasticOut = ElasticOutCurve(1.0);

  // Overshoot curve for scale animations
  static const Curve overshoot = Cubic(0.175, 0.885, 0.32, 1.275);
}

// ─────────────────────────── Animation Presets ───────────────────────────────
class AnimationPresets {
  AnimationPresets._();

  // Fade presets
  static const fadeIn = _FadePreset(
    duration: AppAnimations.entranceFade,
    curve: AppCurves.smoothDecelerate,
    startOpacity: 0.0,
    endOpacity: 1.0,
  );

  static const fadeOut = _FadePreset(
    duration: AppAnimations.fast,
    curve: AppCurves.easeIn,
    startOpacity: 1.0,
    endOpacity: 0.0,
  );

  // Slide presets
  static const slideUp = _SlidePreset(
    duration: AppAnimations.entranceSlide,
    curve: AppCurves.smoothDecelerate,
    startOffset: Offset(0, 0.08),
    endOffset: Offset.zero,
  );

  static const slideDown = _SlidePreset(
    duration: AppAnimations.entranceSlide,
    curve: AppCurves.smoothDecelerate,
    startOffset: Offset(0, -0.08),
    endOffset: Offset.zero,
  );

  static const slideLeft = _SlidePreset(
    duration: AppAnimations.entranceSlide,
    curve: AppCurves.smoothDecelerate,
    startOffset: Offset(0.08, 0),
    endOffset: Offset.zero,
  );

  static const slideRight = _SlidePreset(
    duration: AppAnimations.entranceSlide,
    curve: AppCurves.smoothDecelerate,
    startOffset: Offset(-0.08, 0),
    endOffset: Offset.zero,
  );

  // Scale presets
  static const scaleIn = _ScalePreset(
    duration: AppAnimations.entranceScale,
    curve: AppCurves.overshoot,
    startScale: 0.9,
    endScale: 1.0,
  );

  static const scaleUp = _ScalePreset(
    duration: AppAnimations.fast,
    curve: AppCurves.spring,
    startScale: 1.0,
    endScale: 1.02,
  );

  static const scaleDown = _ScalePreset(
    duration: AppAnimations.instant,
    curve: AppCurves.easeOut,
    startScale: 1.0,
    endScale: 0.96,
  );

  // Modal presets
  static const modalEnter = _ModalPreset(
    duration: AppAnimations.modalEnter,
    curve: AppCurves.modalEnter,
    startScale: 0.92,
    endScale: 1.0,
    startOpacity: 0.0,
    endOpacity: 1.0,
  );

  static const modalExit = _ModalPreset(
    duration: AppAnimations.modalExit,
    curve: AppCurves.modalExit,
    startScale: 1.0,
    endScale: 0.92,
    startOpacity: 1.0,
    endOpacity: 0.0,
  );
}

class _FadePreset {
  final Duration duration;
  final Curve curve;
  final double startOpacity;
  final double endOpacity;

  const _FadePreset({
    required this.duration,
    required this.curve,
    required this.startOpacity,
    required this.endOpacity,
  });
}

class _SlidePreset {
  final Duration duration;
  final Curve curve;
  final Offset startOffset;
  final Offset endOffset;

  const _SlidePreset({
    required this.duration,
    required this.curve,
    required this.startOffset,
    required this.endOffset,
  });
}

class _ScalePreset {
  final Duration duration;
  final Curve curve;
  final double startScale;
  final double endScale;

  const _ScalePreset({
    required this.duration,
    required this.curve,
    required this.startScale,
    required this.endScale,
  });
}

class _ModalPreset {
  final Duration duration;
  final Curve curve;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double endOpacity;

  const _ModalPreset({
    required this.duration,
    required this.curve,
    required this.startScale,
    required this.endScale,
    required this.startOpacity,
    required this.endOpacity,
  });
}

// ─────────────────────────── Animated Widgets ────────────────────────────────

/// Entrance animation that fades and slides content into view
class EntranceAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;
  final bool fadeIn;
  final bool slideIn;
  final bool scaleIn;
  final double initialScale;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.curve = AppCurves.smoothDecelerate,
    this.slideOffset = const Offset(0, 0.05),
    this.fadeIn = true,
    this.slideIn = true,
    this.scaleIn = false,
    this.initialScale = 0.95,
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: widget.fadeIn ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideIn ? widget.slideOffset : Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _scaleAnimation = Tween<double>(
      begin: widget.scaleIn ? widget.initialScale : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _slideAnimation.value.dx * MediaQuery.of(context).size.width,
            _slideAnimation.value.dy * MediaQuery.of(context).size.height,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Staggered list animation for sequential entrance effects
class StaggeredList extends StatefulWidget {
  final List<Widget> children;
  final Duration initialDelay;
  final Duration staggerDelay;
  final Duration itemDuration;
  final Curve curve;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const StaggeredList({
    super.key,
    required this.children,
    this.initialDelay = Duration.zero,
    this.staggerDelay = AppAnimations.staggerDelay,
    this.itemDuration = AppAnimations.entranceSlide,
    this.curve = AppCurves.smoothDecelerate,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 0,
  });

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList> {
  @override
  Widget build(BuildContext context) {
    final animatedChildren = <Widget>[];

    for (int i = 0; i < widget.children.length; i++) {
      final delay = widget.initialDelay +
          Duration(milliseconds: widget.staggerDelay.inMilliseconds * i);

      animatedChildren.add(EntranceAnimation(
        delay: delay,
        duration: widget.itemDuration,
        curve: widget.curve,
        slideOffset: widget.direction == Axis.vertical
            ? const Offset(0, 0.03)
            : const Offset(0.03, 0),
        child: widget.children[i],
      ));

      if (i < widget.children.length - 1 && widget.spacing > 0) {
        animatedChildren.add(SizedBox(
          width: widget.direction == Axis.horizontal ? widget.spacing : 0,
          height: widget.direction == Axis.vertical ? widget.spacing : 0,
        ));
      }
    }

    if (widget.direction == Axis.horizontal) {
      return Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: animatedChildren,
      );
    }

    return Column(
      mainAxisAlignment: widget.mainAxisAlignment,
      crossAxisAlignment: widget.crossAxisAlignment,
      children: animatedChildren,
    );
  }
}

/// Floating animation for decorative elements
class FloatingWidget extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  final Curve curve;
  final Axis direction;
  final double phaseOffset;

  const FloatingWidget({
    super.key,
    required this.child,
    this.amplitude = 10.0,
    this.duration = AppAnimations.floatCycle,
    this.curve = Curves.easeInOut,
    this.direction = Axis.vertical,
    this.phaseOffset = 0.0,
  });

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: -widget.amplitude,
      end: widget.amplitude,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Apply phase offset
    final offsetDuration = Duration(
      milliseconds: (widget.phaseOffset * widget.duration.inMilliseconds).toInt(),
    );

    Future.delayed(offsetDuration, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: widget.direction == Axis.vertical
              ? Offset(0, _animation.value)
              : Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Hover animation wrapper for interactive elements
class HoverAnimator extends StatefulWidget {
  final Widget child;
  final double scaleOnHover;
  final double liftOnHover;
  final Duration duration;
  final Curve curve;
  final bool enabled;
  final VoidCallback? onTap;

  const HoverAnimator({
    super.key,
    required this.child,
    this.scaleOnHover = 1.02,
    this.liftOnHover = 4.0,
    this.duration = AppAnimations.fast,
    this.curve = AppCurves.spring,
    this.enabled = true,
    this.onTap,
  });

  @override
  State<HoverAnimator> createState() => _HoverAnimatorState();
}

class _HoverAnimatorState extends State<HoverAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _liftAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnHover,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _liftAnimation = Tween<double>(
      begin: 0.0,
      end: widget.liftOnHover,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent event) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _onExit(PointerEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_liftAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Tap/Press scale animation
class PressableScale extends StatefulWidget {
  final Widget child;
  final double scaleOnPress;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onTap;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.scaleOnPress = 0.96,
    this.duration = AppAnimations.instant,
    this.curve = AppCurves.easeOut,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleOnPress,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Glow animation for highlighting elements
class GlowAnimator extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double baseBlur;
  final double maxBlur;
  final Duration duration;
  final bool animate;

  const GlowAnimator({
    super.key,
    required this.child,
    required this.glowColor,
    this.baseBlur = 8.0,
    this.maxBlur = 20.0,
    this.duration = const Duration(seconds: 2),
    this.animate = true,
  });

  @override
  State<GlowAnimator> createState() => _GlowAnimatorState();
}

class _GlowAnimatorState extends State<GlowAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _blurAnimation = Tween<double>(
      begin: widget.baseBlur,
      end: widget.maxBlur,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blurAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.4),
                blurRadius: _blurAnimation.value,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Scroll-triggered entrance animation
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;
  final double revealOffset;

  const ScrollReveal({
    super.key,
    required this.child,
    this.duration = AppAnimations.entranceSlide,
    this.curve = AppCurves.smoothDecelerate,
    this.slideOffset = const Offset(0, 0.05),
    this.revealOffset = 0.2,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVisibility(BuildContext context) {
    if (_hasAnimated) return;

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final RenderBox box = renderObject as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;

    final visible = position.dy < screenSize.height * (1 - widget.revealOffset);

    if (visible && !_hasAnimated) {
      _hasAnimated = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility(context);
    });

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility(context);
        return false;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _slideAnimation.value.dx * MediaQuery.of(context).size.width,
              _slideAnimation.value.dy * MediaQuery.of(context).size.height,
            ),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF1E1E2C),
    this.highlightColor = const Color(0xFF3A3A4C),
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Pulse animation for attention-grabbing elements
class PulseAnimator extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulseAnimator({
    super.key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulseAnimator> createState() => _PulseAnimatorState();
}

class _PulseAnimatorState extends State<PulseAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────── Page Route Transitions ──────────────────────────

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeSlidePageRoute({required this.page})
      : super(
          transitionDuration: AppAnimations.medium,
          reverseTransitionDuration: AppAnimations.fast,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppCurves.smoothDecelerate,
            ));

            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppCurves.smoothDecelerate,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

class ScaleFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadePageRoute({required this.page})
      : super(
          transitionDuration: AppAnimations.modalEnter,
          reverseTransitionDuration: AppAnimations.modalExit,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppCurves.modalEnter,
            ));

            final scaleAnimation = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppCurves.modalEnter,
            ));

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            );
          },
        );
}
