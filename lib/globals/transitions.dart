import 'package:flutter/material.dart';

/// Global transition builder for the custom zoom-fade effect.
/// Uses one cohesive motion so incoming/outgoing pages feel synchronized.
Widget zoomFadeTransitionBuilder(
  Widget child,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutCubicEmphasized,
  );

  // Outgoing widgets run this animation in reverse, so we invert the tween to
  // keep a slight zoom-in while fading out.
  final isOutgoing = animation.status == AnimationStatus.reverse;
  final scale = Tween<double>(
    begin: isOutgoing ? 1.06 : 0.90,
    end: isOutgoing ? 1.00 : 1.00,
  ).animate(curved);

  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: scale,
      child: child,
    ),
  );
}

/// Corresponding PageTransitionsBuilder for standard router pushes.
class ZoomFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const ZoomFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubicEmphasized,
    );

    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.90, end: 1.00).animate(curved),
        child: child,
      ),
    );
  }
}
