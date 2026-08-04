import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'card_flip_controller.dart';

/// Y-axis flip between [frontWidget] and [backWidget] (study card shell).
class CardFlip extends HookWidget {
  const CardFlip({
    required this.frontWidget,
    required this.backWidget,
    required this.flipCardController,
    this.onFlip,
    super.key,
    this.duration = const Duration(milliseconds: 240),
    this.height = 200,
    this.width = 200,
  });

  final Widget frontWidget;
  final Widget backWidget;
  final Duration duration;
  final double height;
  final double width;
  final CardFlipController? flipCardController;
  final ValueChanged<bool>? onFlip;

  @override
  Widget build(BuildContext context) {
    final internalIsFront = useRef(true);
    final onFlipRef = useRef(onFlip);
    onFlipRef.value = onFlip;
    final controller = useAnimationController(duration: duration);
    final backAnimation = useMemoized(
      () => TweenSequence(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween(
            begin: 0.0,
            end: math.pi / 2,
          ).chain(CurveTween(curve: Curves.linear)),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(math.pi / 2),
          weight: 50.0,
        ),
      ]).animate(controller),
      [controller],
    );
    final frontAnimation = useMemoized(
      () => TweenSequence(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(math.pi / 2),
          weight: 50.0,
        ),
        TweenSequenceItem<double>(
          tween: Tween(
            begin: -math.pi / 2,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.linear)),
          weight: 50.0,
        ),
      ]).animate(controller),
      [controller],
    );
    final initializedFromExternal = useRef(false);
    final currentControllerRef = useRef<CardFlipController?>(null);
    final showFrontNotifier = useMemoized(() => ValueNotifier(true), const []);
    final toggleSideRef = useRef<VoidCallback>(() {});

    Future<void> triggerFlip(bool targetIsFront) async {
      if (targetIsFront) {
        await controller.reverse();
      } else {
        await controller.forward();
      }
      onFlipRef.value?.call(targetIsFront);
    }

    void handleControllerChange() {
      final external = currentControllerRef.value;
      if (external == null) return;
      final targetIsFront = external.isFront;
      internalIsFront.value = targetIsFront;
      triggerFlip(targetIsFront);
    }

    useEffect(() {
      final external = flipCardController;
      if (external != null && !initializedFromExternal.value) {
        initializedFromExternal.value = true;
        internalIsFront.value = external.isFront;
        if (!internalIsFront.value) {
          controller.value = 1.0;
        }
      }
      return null;
    }, [flipCardController, controller]);

    useEffect(() {
      final previous = currentControllerRef.value;
      if (previous != flipCardController) {
        previous?.removeListener(handleControllerChange);
        currentControllerRef.value = flipCardController;
        flipCardController?.addListener(handleControllerChange);
        final external = flipCardController;
        if (external != null) {
          if (external.isFront) {
            controller.reverse();
          } else {
            controller.forward();
          }
        }
      }
      return () {
        flipCardController?.removeListener(handleControllerChange);
      };
    }, [flipCardController, controller]);

    void toggleSide() {
      if (flipCardController != null) {
        flipCardController!.flip();
      } else {
        internalIsFront.value = !internalIsFront.value;
        triggerFlip(internalIsFront.value);
      }
    }

    toggleSideRef.value = toggleSide;

    useEffect(() {
      void onTick() {
        final val = controller.value < 0.5;
        if (showFrontNotifier.value != val) showFrontNotifier.value = val;
      }

      controller.addListener(onTick);
      return () => controller.removeListener(onTick);
    }, [controller, showFrontNotifier]);

    return ValueListenableBuilder<bool>(
      valueListenable: showFrontNotifier,
      builder: (context, showFront, _) {
        return Stack(
          children: [
            IgnorePointer(
              ignoring: !showFront,
              child: GestureDetector(
                onTap: showFront ? () => toggleSideRef.value() : null,
                child: _FlipCardFace(
                  animation: backAnimation,
                  height: height,
                  width: width,
                  child: frontWidget,
                ),
              ),
            ),
            IgnorePointer(
              ignoring: showFront,
              child: GestureDetector(
                onTap: showFront ? null : () => toggleSideRef.value(),
                child: _FlipCardFace(
                  animation: frontAnimation,
                  height: height,
                  width: width,
                  child: backWidget,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FlipCardFace extends HookWidget {
  static const _kCardRadius = 16.0;

  const _FlipCardFace({
    required this.child,
    required this.animation,
    required this.height,
    required this.width,
  });

  final Widget child;
  final Animation<double> animation;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: _builder,
      child: SizedBox(
        height: height,
        width: width,
        child: Card(
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          surfaceTintColor: Colors.transparent,
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kCardRadius),
          ),
          borderOnForeground: false,
          child: child,
        ),
      ),
    );
  }

  Widget _builder(BuildContext context, Widget? child) {
    var transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.001);
    transform.rotateY(animation.value);
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: child,
    );
  }
}
