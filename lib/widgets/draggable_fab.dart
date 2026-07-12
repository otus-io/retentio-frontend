import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _kFabSize = 40.0;
const double _kFabBorderOpacity = 0.12;
const double _kFabBgTint = 0.08;
const double _kEdgeMargin = 8.0;

/// A floating action button that the user can drag to reposition.
///
/// Pass [storageKey] to persist the position across sessions via
/// SharedPreferences. Omit it to use an in-session position only.
///
/// Wrap the screen's Scaffold in a [Stack] and place [DraggableFab] as the
/// last child so it always floats above the content.
class DraggableFab extends StatefulWidget {
  const DraggableFab({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.storageKey,
    this.initialRight = 16,
    this.initialBottom = 16,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final String? storageKey;
  final double initialRight;
  final double initialBottom;

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab> {
  double _right = 16;
  double _bottom = 16;
  bool _dragging = false;
  bool _positionReady = false;

  String get _keyRight => '${widget.storageKey}_right';
  String get _keyBottom => '${widget.storageKey}_bottom';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_positionReady) {
      _positionReady = true;
      _loadPosition();
    }
  }

  Future<void> _loadPosition() async {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final defaultBottom = widget.initialBottom + safeBottom;

    if (widget.storageKey == null) {
      setState(() {
        _right = widget.initialRight;
        _bottom = defaultBottom;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _right = prefs.getDouble(_keyRight) ?? widget.initialRight;
      _bottom = prefs.getDouble(_keyBottom) ?? defaultBottom;
    });
  }

  Future<void> _savePosition() async {
    if (widget.storageKey == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRight, _right);
    await prefs.setDouble(_keyBottom, _bottom);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          right: _right,
          bottom: _bottom,
          child: GestureDetector(
            onPanStart: (_) => setState(() => _dragging = true),
            onPanUpdate: (d) {
              setState(() {
                _right = (_right - d.delta.dx)
                    .clamp(_kEdgeMargin, size.width - _kFabSize - _kEdgeMargin);
                _bottom = (_bottom - d.delta.dy).clamp(
                  safeBottom + _kEdgeMargin,
                  size.height - _kFabSize - _kEdgeMargin,
                );
              });
            },
            onPanEnd: (_) {
              setState(() => _dragging = false);
              _savePosition();
            },
            child: Tooltip(
              message: widget.tooltip,
              child: Material(
                color: Color.lerp(
                  scheme.surfaceContainerHighest,
                  scheme.primary,
                  _kFabBgTint,
                ),
                shape: CircleBorder(
                  side: BorderSide(
                    color: scheme.primary.withValues(alpha: _kFabBorderOpacity),
                  ),
                ),
                elevation: 0,
                child: InkWell(
                  onTap: _dragging ? null : widget.onPressed,
                  customBorder: const CircleBorder(),
                  child: SizedBox.square(
                    dimension: _kFabSize,
                    child: Icon(
                      LucideIcons.plus,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
