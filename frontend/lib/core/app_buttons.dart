import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';

// ─────────────────────────── Button Style Enum ───────────────────────────────
enum AppButtonStyle {
  primary, // filled gradient
  secondary, // filled flat accent
  outline, // border only
  ghost, // no border, tinted bg on hover
}

// ─────────────────────────── AppButton ───────────────────────────────────────
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120), value: 1);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  void _onTapDown(_) {
    if (!_disabled) {
      _scaleCtrl.forward();
    }
  }

  void _onTapUp(_) {
    _scaleCtrl.reverse();
  }

  void _onTapCancel() {
    _scaleCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return MouseRegion(
      cursor:
          _disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) {
        if (!_disabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _disabled ? null : widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: _decoration(t),
            child: Center(child: _content(t)),
          ),
        ),
      ),
    );
  }

  BoxDecoration _decoration(AppThemeData t) {
    final disabled = _disabled;
    switch (widget.style) {
      case AppButtonStyle.primary:
        return BoxDecoration(
          gradient: disabled ? null : t.primaryGradient,
          color: disabled ? t.border : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: (_hovered && !disabled) ? [t.primaryGlow] : [],
        );
      case AppButtonStyle.secondary:
        return BoxDecoration(
          color: disabled
              ? t.border
              : (_hovered ? t.accent.withValues(alpha: 0.85) : t.accent),
          borderRadius: BorderRadius.circular(30),
          boxShadow: (_hovered && !disabled) ? [t.accentGlow] : [],
        );
      case AppButtonStyle.outline:
        return BoxDecoration(
          color:
              _hovered ? t.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: disabled ? t.border : (_hovered ? t.primary : t.border),
              width: 1.5),
        );
      case AppButtonStyle.ghost:
        return BoxDecoration(
          color:
              _hovered ? t.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        );
    }
  }

  Widget _content(AppThemeData t) {
    if (widget.isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
            strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
      );
    }
    final color = _contentColor(t);
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: widget.fontSize + 2, color: color),
          const SizedBox(width: 8),
          Text(widget.label,
              style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      );
    }
    return Text(widget.label,
        style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            color: color));
  }

  Color _contentColor(AppThemeData t) {
    if (_disabled) return t.textMuted;
    switch (widget.style) {
      case AppButtonStyle.primary:
        return Colors.white;
      case AppButtonStyle.secondary:
        return Colors.white;
      case AppButtonStyle.outline:
        return _hovered ? t.primary : t.text;
      case AppButtonStyle.ghost:
        return _hovered ? t.primary : t.textMuted;
    }
  }
}

// ─────────────────────────── Icon-only Button ────────────────────────────────
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const AppIconButton(
      {super.key,
      required this.icon,
      this.onPressed,
      this.tooltip,
      this.color});

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final c = widget.color ?? t.primary;
    final btn = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovered ? c.withValues(alpha: 0.12) : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: _hovered
                ? [BoxShadow(color: c.withValues(alpha: 0.25), blurRadius: 10)]
                : [],
          ),
          child: Icon(widget.icon, size: 22, color: _hovered ? c : t.textMuted),
        ),
      ),
    );
    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}
