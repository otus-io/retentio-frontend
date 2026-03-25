import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_flip_controller.dart';

/// Y-axis flip between [frontWidget] and [backWidget] (study card shell).
class CardFlip extends StatefulWidget {
  const CardFlip({
    required this.frontWidget,
    required this.backWidget,
    required this.flipCardController,
    this.onFlip,
    super.key,
    this.duration = const Duration(milliseconds: 200),
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
  State createState() => _CardFlipState();
}

class _CardFlipState extends State<CardFlip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _frontAnimation;
  late Animation<double> _backAnimation;

  bool _internalIsFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    widget.flipCardController?.addListener(_handleControllerChange);
    if (widget.flipCardController != null) {
      _internalIsFront = widget.flipCardController!.isFront;
      if (!_internalIsFront) {
        _controller.value = 1.0;
      }
    }
    _backAnimation = TweenSequence(<TweenSequenceItem<double>>[
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
    ]).animate(_controller);

    _frontAnimation = TweenSequence(<TweenSequenceItem<double>>[
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
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(CardFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flipCardController != oldWidget.flipCardController) {
      oldWidget.flipCardController?.removeListener(_handleControllerChange);
      widget.flipCardController?.addListener(_handleControllerChange);

      if (widget.flipCardController != null) {
        if (widget.flipCardController!.isFront) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    widget.flipCardController?.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (widget.flipCardController == null) return;

    final bool targetIsFront = widget.flipCardController!.isFront;
    _internalIsFront = targetIsFront;
    _triggerFlip(targetIsFront);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleSide,
          child: _FlipCardFace(
            animation: _backAnimation,
            height: widget.height,
            width: widget.width,
            child: widget.frontWidget,
          ),
        ),
        GestureDetector(
          onTap: _toggleSide,
          child: _FlipCardFace(
            animation: _frontAnimation,
            height: widget.height,
            width: widget.width,
            child: widget.backWidget,
          ),
        ),
      ],
    );
  }

  Future<void> _triggerFlip(bool targetIsFront) async {
    if (targetIsFront) {
      await _controller.reverse();
    } else {
      await _controller.forward();
    }

    if (widget.onFlip != null) {
      widget.onFlip!(targetIsFront);
    }
  }

  void _toggleSide() {
    if (widget.flipCardController != null) {
      widget.flipCardController!.flip();
    } else {
      setState(() {
        _internalIsFront = !_internalIsFront;
      });
      _triggerFlip(_internalIsFront);
    }
  }
}

class _FlipCardFace extends StatelessWidget {
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
    return AnimatedBuilder(
      animation: animation,
      builder: _builder,
      child: SizedBox(
        height: height,
        width: width,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
