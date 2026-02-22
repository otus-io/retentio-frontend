import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'flash_card_controller.dart';

/// UI flash card, commonly found in language teaching to children
class FlashCard extends StatefulWidget {
  /// constructor: Default height 200dp, width 200dp, duration  500 milliseconds
  const FlashCard({
    required this.frontWidget,
    required this.backWidget,
    required this.flashCardController,
    this.onFlip,
    super.key,
    this.duration = const Duration(milliseconds: 200),
    this.height = 200,
    this.width = 200,
  });

  /// this is the front of the card
  final Widget frontWidget;

  /// this is the back of the card
  final Widget backWidget;

  /// flip time
  final Duration duration;

  /// height of card
  final double height;

  /// width of card
  final double width;
  final FlashCardController? flashCardController;
  final ValueChanged<bool>? onFlip;

  @override
  State createState() => _FlashCardState();
}

class _FlashCardState extends State<FlashCard>
    with SingleTickerProviderStateMixin {
  /// controller flip animation
  late AnimationController _controller;

  /// animation for flip from front to back
  late Animation<double> _frontAnimation;

  ///animation for flip from back  to front
  late Animation<double> _backAnimation;

  bool _internalIsFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    // 1. 如果传入了 Controller，监听它
    widget.flashCardController?.addListener(_handleControllerChange);
    // 同步初始状态
    if (widget.flashCardController != null) {
      _internalIsFront = widget.flashCardController!.isFront;
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
  void didUpdateWidget(FlashCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flashCardController != oldWidget.flashCardController) {
      oldWidget.flashCardController?.removeListener(_handleControllerChange);
      widget.flashCardController?.addListener(_handleControllerChange);

      // 同步新控制器的状态
      if (widget.flashCardController != null) {
        if (widget.flashCardController!.isFront) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    widget.flashCardController?.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  /// 监听回调函数
  void _handleControllerChange() {
    if (widget.flashCardController == null) return;

    final bool targetIsFront = widget.flashCardController!.isFront;
    _internalIsFront = targetIsFront; // 同步内部状态
    _triggerFlip(targetIsFront);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleSide,
          child: AnimatedCard(
            animation: _backAnimation,
            height: widget.height,
            width: widget.width,
            child: widget.frontWidget,
          ),
        ),
        GestureDetector(
          onTap: _toggleSide,
          child: AnimatedCard(
            animation: _frontAnimation,
            height: widget.height,
            width: widget.width,
            child: widget.backWidget,
          ),
        ),
      ],
    );
  }

  /// 统一处理翻转动画和回调触发
  Future<void> _triggerFlip(bool targetIsFront) async {
    if (targetIsFront) {
      await _controller.reverse();
    } else {
      await _controller.forward();
    }

    // 触发回调
    if (widget.onFlip != null) {
      widget.onFlip!(targetIsFront);
    }
  }

  /// when user onTap, It will run function
  void _toggleSide() {
    if (widget.flashCardController != null) {
      widget.flashCardController!.flip();
    } else {
      // 如果没有控制器，退化为内部自管模式
      setState(() {
        _internalIsFront = !_internalIsFront;
      });
      _triggerFlip(_internalIsFront);
    }
  }
}

class AnimatedCard extends StatelessWidget {
  const AnimatedCard({
    required this.child,
    required this.animation,
    required this.height,
    required this.width,
    super.key,
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
            borderRadius: BorderRadius.circular(20),
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
