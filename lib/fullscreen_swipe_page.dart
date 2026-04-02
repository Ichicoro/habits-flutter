// full_width_back_gesture.dart
//
// Drop-in full-width swipe-back for Flutter.
//
// USAGE
// ─────
// 1. Wrap your MaterialApp (or Navigator) with FullWidthBackGestureApp:
//
//      FullWidthBackGestureApp(
//        child: MaterialApp(...),
//      )
//
// 2. Or apply only to specific routes by using FullWidthPageRoute:
//
//      Navigator.push(context, FullWidthPageRoute(builder: (_) => MyPage()));
//
// 3. Or set it globally via ThemeData:
//
//      theme: ThemeData(
//        pageTransitionsTheme: fullWidthPageTransitionsTheme,
//      )

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// ─── Public API ───────────────────────────────────────────────────────────────

/// Wrap your [MaterialApp] with this to enable full-width swipe-back globally.
class FullWidthBackGestureApp extends StatelessWidget {
  const FullWidthBackGestureApp({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Inject our custom page-transitions theme into whatever theme is already set.
    return Builder(
      builder: (context) {
        final existing = Theme.of(context);
        return Theme(
          data: (existing).copyWith(
            pageTransitionsTheme: fullWidthPageTransitionsTheme,
          ),
          child: child,
        );
      },
    );
  }
}

/// A [PageTransitionsTheme] that enables full-width swipe-back on all platforms.
const fullWidthPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.iOS: _FullWidthCupertinoPageTransitionsBuilder(),
    TargetPlatform.android: _FullWidthCupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: _FullWidthCupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: _FullWidthCupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: _FullWidthCupertinoPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _FullWidthCupertinoPageTransitionsBuilder(),
  },
);

/// A [PageRoute] that uses the Cupertino slide transition + full-width swipe back.
class FullWidthPageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  FullWidthPageRoute({
    required this.builder,
    super.settings,
    this.maintainStateValue = true,
    super.fullscreenDialog,
  });

  final WidgetBuilder builder;
  final bool maintainStateValue;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String? get title => null;

  @override
  bool get maintainState => maintainStateValue;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return const _FullWidthCupertinoPageTransitionsBuilder().buildTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

// ─── Implementation ───────────────────────────────────────────────────────────

class _FullWidthCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FullWidthCupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FullWidthBackGestureDetector<T>(
      enabledCallback: () => _isPopGestureEnabled(route),
      onStartPopGesture: () => _startPopGesture(route),
      child: CupertinoPageTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: _isPopGestureInProgress(route),
        child: child,
      ),
    );
  }

  static bool _isPopGestureEnabled<T>(PageRoute<T> route) {
    if (route.isFirst) return false;
    if (route.willHandlePopInternally) return false;
    if (route.popDisposition == RoutePopDisposition.doNotPop) return false;
    if (route.fullscreenDialog) return false;
    if (route.animation!.status != AnimationStatus.completed) return false;
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) {
      return false;
    }
    if (isPopGestureInProgress(route)) return false;
    return true;
  }

  static bool _isPopGestureInProgress<T>(PageRoute<T> route) {
    return isPopGestureInProgress(route);
  }

  static bool isPopGestureInProgress(PageRoute<dynamic> route) {
    return route.navigator!.userGestureInProgress;
  }

  static _CupertinoBackGestureController<T> _startPopGesture<T>(
    PageRoute<T> route,
  ) {
    assert(_isPopGestureEnabled(route));
    return _CupertinoBackGestureController<T>(
      navigator: route.navigator!,
      controller: route.controller!,
    );
  }
}

// Full-width gesture detector (replaces Flutter's edge-only 20px detector).
class _FullWidthBackGestureDetector<T> extends StatefulWidget {
  const _FullWidthBackGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  final Widget child;
  final ValueGetter<bool> enabledCallback;
  final ValueGetter<_CupertinoBackGestureController<T>> onStartPopGesture;

  @override
  _FullWidthBackGestureDetectorState<T> createState() =>
      _FullWidthBackGestureDetectorState<T>();
}

class _FullWidthBackGestureDetectorState<T>
    extends State<_FullWidthBackGestureDetector<T>> {
  _CupertinoBackGestureController<T>? _backGestureController;

  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragEnd(
      _convertToLogical(
        details.velocity.pixelsPerSecond.dx / context.size!.width,
      ),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Full width — no edge constraint at all.
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

// Unchanged from Flutter source — drives the pop animation.
class _CupertinoBackGestureController<T> {
  _CupertinoBackGestureController({
    required this.navigator,
    required this.controller,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const _kMinFlingVelocity = 1.0;

    final bool animateForward;
    if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastLinearToSlowEaseIn,
      );
    } else {
      navigator.pop();
      if (controller.isAnimating) {
        controller.animateBack(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastLinearToSlowEaseIn,
        );
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
