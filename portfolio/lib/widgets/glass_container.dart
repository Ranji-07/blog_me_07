import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';

/// A glassmorphism card that automatically adapts to dark/light mode.
/// On dark mode: deep blur + green/white tinted border.
/// On light mode: soft white blur + blue-tinted border.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool glowPrimary;
  final bool glowAccent;
  final bool enableHover;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.glowPrimary = false,
    this.glowAccent = false,
    this.enableHover = false,
  });

  @override
  Widget build(BuildContext context) {
    if (enableHover) {
      return _HoverGlassContainer(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        borderRadius: borderRadius,
        glowPrimary: glowPrimary,
        glowAccent: glowAccent,
        child: child,
      );
    }

    return _buildContainer(context);
  }

  Widget _buildContainer(BuildContext context) {
    final t = AppTheme.of(context);
    final radius = borderRadius ?? BorderRadius.circular(20);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: -4),
          if (glowPrimary) t.primaryGlow,
          if (glowAccent) t.accentGlow,
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: radius,
              border: Border.all(
                color: t.isDark
                    ? t.primary.withValues(alpha: 0.18)
                    : t.border.withValues(alpha: 0.6),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: t.isDark
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02)
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.5)
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass container with hover animations
class _HoverGlassContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool glowPrimary;
  final bool glowAccent;

  const _HoverGlassContainer({
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.glowPrimary = false,
    this.glowAccent = false,
  });

  @override
  State<_HoverGlassContainer> createState() => _HoverGlassContainerState();
}

class _HoverGlassContainerState extends State<_HoverGlassContainer>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _liftAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
    _liftAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.spring),
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.smoothDecelerate),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final radius = widget.borderRadius ?? BorderRadius.circular(20);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_liftAnimation.value),
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: widget.margin,
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isHovered ? 0.25 : 0.15),
                    blurRadius: _isHovered ? 36 : 24,
                    spreadRadius: _isHovered ? 0 : -4,
                    offset: Offset(0, _isHovered ? 10 : 0),
                  ),
                  if (widget.glowPrimary || _isHovered)
                    BoxShadow(
                      color: t.primary.withValues(
                        alpha: (widget.glowPrimary ? 0.35 : 0.2) * (_isHovered ? 1.2 : 1.0),
                      ),
                      blurRadius: 20 + (_glowAnimation.value * 15),
                      spreadRadius: 2,
                    ),
                  if (widget.glowAccent) t.accentGlow,
                ],
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: AppAnimations.fast,
                    padding: widget.padding ?? const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: t.isDark
                          ? Colors.white.withValues(alpha: _isHovered ? 0.08 : 0.05)
                          : Colors.white.withValues(alpha: _isHovered ? 0.85 : 0.72),
                      borderRadius: radius,
                      border: Border.all(
                        color: _isHovered
                            ? t.primary.withValues(alpha: 0.4)
                            : (t.isDark
                                ? t.primary.withValues(alpha: 0.18)
                                : t.border.withValues(alpha: 0.6)),
                        width: 1.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: t.isDark
                            ? [
                                Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.08),
                                Colors.white.withValues(alpha: _isHovered ? 0.04 : 0.02)
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.5)
                              ],
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated glass card with entrance animation
class AnimatedGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool glowPrimary;
  final bool glowAccent;
  final bool enableHover;
  final Duration delay;

  const AnimatedGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.glowPrimary = false,
    this.glowAccent = false,
    this.enableHover = true,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return EntranceAnimation(
      delay: delay,
      duration: AppAnimations.entranceSlide,
      curve: AppCurves.smoothDecelerate,
      child: GlassContainer(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        borderRadius: borderRadius,
        glowPrimary: glowPrimary,
        glowAccent: glowAccent,
        enableHover: enableHover,
        child: child,
      ),
    );
  }
}
