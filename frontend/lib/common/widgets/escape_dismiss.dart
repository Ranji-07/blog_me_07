import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Moves primary focus into this subtree one frame after it is built.
///
/// A freshly pushed modal route parks primary focus on the route's scope
/// node, and [Focus] with `autofocus: true` never applies because the
/// scope already held focus when the request registered. Keyboard handling
/// (including Flutter's Escape-to-dismiss and any [CallbackShortcuts]) only
/// walks up from the focused node, so overlays whose focus stays on the
/// scope node can never see key events. Grabbing focus explicitly puts that
/// walk through the overlay's own shortcuts from the first keypress.
class InitialFocus extends StatefulWidget {
  final Widget child;

  const InitialFocus({super.key, required this.child});

  @override
  State<InitialFocus> createState() => _InitialFocusState();
}

class _InitialFocusState extends State<InitialFocus> {
  final FocusNode _node = FocusNode(debugLabel: 'initial-focus');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(focusNode: _node, child: widget.child);
  }
}

/// Wraps [child] so the Escape key pops the enclosing route.
///
/// Flutter maps Escape to [DismissIntent] but the route-level action for it
/// is only reachable when focus is inside the route content, so this widget
/// pairs an Escape binding with an [InitialFocus] grab. Routes that need no
/// custom exit motion use this wrapper; routes with their own exit
/// choreography (for example the resume paper flight) wire Escape themselves
/// so the exit motion runs before the pop.
class EscapeDismiss extends StatelessWidget {
  final Widget child;

  const EscapeDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: InitialFocus(child: child),
    );
  }
}
