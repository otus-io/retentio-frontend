import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:retentio/extensions/widget_extension.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';
import 'package:retentio/widgets/buttons_tab_bar.dart';
import 'package:retentio/widgets/common_net_image.dart';

class CardContentContainer extends HookWidget {
  static const _kAnimDuration = Duration(milliseconds: 220);

  const CardContentContainer({
    super.key,
    required this.cards,
    required this.color,
    this.accentColor,
    this.textColor,
    this.trailing,
    this.typographyDeckId,
    this.typographyIsFront = true,
  });

  final List<CardSlot> cards;
  final Color color;
  final Color? accentColor;
  final Color? textColor;
  final Widget? trailing;
  final String? typographyDeckId;
  final bool typographyIsFront;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final effectiveAccent = accentColor ?? color;
    final effectiveText = textColor ?? scheme.onSurface;

    if (cards.isEmpty) {
      return _EmptyCardContent(
        color: color,
        trailing: trailing,
        typographyDeckId: typographyDeckId,
        typographyIsFront: typographyIsFront,
      );
    }

    final cloudSlots = cards.where((slot) => slot.items.isNotEmpty).toList();
    if (cloudSlots.length < 3) {
      return _TabbedFieldsView(
        cards: cards,
        color: color,
        accentColor: effectiveAccent,
        textColor: effectiveText,
        scheme: scheme,
        textTheme: textTheme,
        trailing: trailing,
        typographyDeckId: typographyDeckId,
        typographyIsFront: typographyIsFront,
      );
    }

    final selected = useState<int?>(null);
    final chips = <_SphereChipData>[];

    for (var i = 0; i < cards.length; i++) {
      final slot = cards[i];
      if (slot.items.isEmpty) continue;
      for (final item in slot.items) {
        final chip = _itemChipData(i, item);
        if (chip != null) chips.add(chip);
      }
    }

    if (chips.isEmpty) {
      return _EmptyCardContent(
        color: color,
        trailing: trailing,
        typographyDeckId: typographyDeckId,
        typographyIsFront: typographyIsFront,
      );
    }

    final hasSelection =
        selected.value != null && selected.value! < cards.length;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: _kAnimDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: hasSelection
                ? _SelectedFieldPane(
                    key: ValueKey('field-${selected.value}'),
                    slot: cards[selected.value!],
                    color: color,
                    accentColor: effectiveAccent,
                    textColor: effectiveText,
                    surfaceColor: scheme.surface,
                    labelStyle: textTheme.labelLarge,
                    typographyDeckId: typographyDeckId,
                    typographyIsFront: typographyIsFront,
                    onClose: () => selected.value = null,
                  )
                : _SphereCloud(
                    key: const ValueKey('cloud'),
                    chips: chips,
                    accentColor: effectiveAccent,
                    textColor: effectiveText,
                    onTap: (slotIndex) => selected.value = slotIndex,
                  ),
          ),
        ),
        if (trailing != null) Positioned(top: 4, right: 4, child: trailing!),
      ],
    );
  }
}

class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent({
    required this.color,
    required this.trailing,
    required this.typographyDeckId,
    required this.typographyIsFront,
  });

  final Color color;
  final Widget? trailing;
  final String? typographyDeckId;
  final bool typographyIsFront;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FactContent(
            items: const [],
            color: color,
            typographyDeckId: typographyDeckId,
            typographyIsFront: typographyIsFront,
          ),
        ),
        if (trailing != null) Positioned(top: 4, right: 4, child: trailing!),
      ],
    );
  }
}

String _truncate(String s, int max) {
  final trimmed = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (trimmed.length <= max) return trimmed;
  return '${trimmed.substring(0, max - 1)}…';
}

class _TabbedFieldsView extends StatelessWidget {
  const _TabbedFieldsView({
    required this.cards,
    required this.color,
    required this.accentColor,
    required this.textColor,
    required this.scheme,
    required this.textTheme,
    required this.trailing,
    required this.typographyDeckId,
    required this.typographyIsFront,
  });

  static const _kTabBarBorderWidth = 0.8;
  static const _kTabRadius = 12.0;
  static const _kTabContentPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );

  final List<CardSlot> cards;
  final Color color;
  final Color accentColor;
  final Color textColor;
  final ColorScheme scheme;
  final TextTheme textTheme;
  final Widget? trailing;
  final String? typographyDeckId;
  final bool typographyIsFront;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: cards.length,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: _kTabBarBorderWidth,
                  color: scheme.outline.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                ButtonsTabBar(
                  backgroundColor: Colors.transparent,
                  unselectedBackgroundColor: Colors.transparent,
                  borderWidth: 0,
                  radius: _kTabRadius,
                  borderColor: Colors.transparent,
                  unselectedBorderColor: Colors.transparent,
                  contentPadding: _kTabContentPadding,
                  buttonMargin: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 5,
                  ),
                  labelStyle:
                      textTheme.labelMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                  unselectedLabelStyle:
                      textTheme.labelMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ) ??
                      TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                  tabs: cards.map((slot) => Tab(text: slot.field)).toList(),
                ).expanded(),
                ?trailing,
              ],
            ),
          ),
          TabBarView(
            children: cards
                .map(
                  (slot) => FactContent(
                    items: slot.items,
                    color: color,
                    typographyDeckId: typographyDeckId,
                    typographyIsFront: typographyIsFront,
                  ),
                )
                .toList(),
          ).expanded(),
        ],
      ),
    );
  }
}

String _itemLabel(Item item) {
  switch (item.type) {
    case 'json':
      return '';
    case 'image':
      return '🖼';
    case 'video':
      return '🎬';
    case 'audio':
      final value = item.value.trim();
      return value.isEmpty ? '🔊' : '🔊 ${_truncate(value, 18)}';
    default:
      return _truncate(item.value, 24);
  }
}

class _SphereChipData {
  const _SphereChipData({
    required this.slotIndex,
    required this.label,
    this.imageUrl,
  });

  final int slotIndex;
  final String label;
  final String? imageUrl;
}

_SphereChipData? _itemChipData(int slotIndex, Item item) {
  switch (item.type) {
    case 'json':
      return null;
    case 'image':
      final url = item.value.trim();
      if (url.isEmpty) return null;
      return _SphereChipData(slotIndex: slotIndex, label: '', imageUrl: url);
    default:
      final label = _itemLabel(item);
      if (label.isEmpty) return null;
      return _SphereChipData(slotIndex: slotIndex, label: label);
  }
}

class _SphereCloud extends HookWidget {
  const _SphereCloud({
    super.key,
    required this.chips,
    required this.accentColor,
    required this.textColor,
    required this.onTap,
  });

  final List<_SphereChipData> chips;
  final Color accentColor;
  final Color textColor;
  final void Function(int slotIndex) onTap;

  static const double _friction = 0.94;
  static const double _dragSensitivity = 0.005;
  static const double _maxPitch = 1.1;
  static const double _perspective = 0.0018;
  static const double _radiusFactor = 0.40;
  static const double _centerZThreshold = 0.82;

  @override
  Widget build(BuildContext context) {
    final rotX = useState(0.15);
    final rotY = useState(0.0);
    final velX = useRef(0.0);
    final velY = useRef(0.0);
    final dragging = useRef(false);

    final ticker = useAnimationController(duration: const Duration(days: 1));

    useEffect(() {
      ticker.repeat();

      void onTick() {
        if (dragging.value) return;
        if (velX.value.abs() < 1e-5 && velY.value.abs() < 1e-5) return;
        velY.value *= _friction;
        velX.value *= _friction;
        rotY.value += velY.value;
        rotX.value = (rotX.value + velX.value).clamp(-_maxPitch, _maxPitch);
      }

      ticker.addListener(onTick);
      return () => ticker.removeListener(onTick);
    }, [ticker]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final radius = math.min(width, height) * _radiusFactor;
        final centerX = width / 2;
        final centerY = height / 2;

        final positioned = <_ProjectedChip>[];
        for (var i = 0; i < chips.length; i++) {
          final point = _fibonacciPoint(i, chips.length);
          final rotated = _rotateXY(point, rotX.value, rotY.value);
          positioned.add(
            _ProjectedChip(
              index: i,
              x: rotated[0],
              y: rotated[1],
              z: rotated[2],
            ),
          );
        }
        positioned.sort((a, b) => a.z.compareTo(b.z));

        var centerIdx = 0;
        var centerZ = -2.0;
        for (final point in positioned) {
          if (point.z > centerZ) {
            centerZ = point.z;
            centerIdx = point.index;
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {
            dragging.value = true;
            velX.value = 0;
            velY.value = 0;
          },
          onPanUpdate: (details) {
            rotY.value += details.delta.dx * _dragSensitivity;
            rotX.value = (rotX.value - details.delta.dy * _dragSensitivity)
                .clamp(-_maxPitch, _maxPitch);
            velY.value = details.delta.dx * _dragSensitivity;
            velX.value = -details.delta.dy * _dragSensitivity;
          },
          onPanEnd: (_) {
            dragging.value = false;
          },
          onPanCancel: () {
            dragging.value = false;
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SphereConnectionsPainter(
                      points: positioned,
                      radius: radius,
                      cx: centerX,
                      cy: centerY,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              for (final point in positioned)
                Positioned(
                  left: centerX + point.x * radius,
                  top: centerY + point.y * radius,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -0.5),
                    child: _SphereChip(
                      data: chips[point.index],
                      z: point.z,
                      perspective: _perspective,
                      isCentered: point.index == centerIdx &&
                          point.z >= _centerZThreshold,
                      accentColor: accentColor,
                      textColor: textColor,
                      onTap: () => onTap(chips[point.index].slotIndex),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SphereConnectionsPainter extends CustomPainter {
  _SphereConnectionsPainter({
    required this.points,
    required this.radius,
    required this.cx,
    required this.cy,
    required this.color,
  });

  final List<_ProjectedChip> points;
  final double radius;
  final double cx;
  final double cy;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final a = points[i];
        final b = points[j];
        final depth = ((a.z + b.z) / 2 + 1) / 2;
        final alpha = (0.05 + depth * 0.35).clamp(0.0, 0.4);
        final paint = Paint()
          ..color = color.withValues(alpha: alpha)
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;

        final p1 = Offset(cx + a.x * radius, cy + a.y * radius);
        final p2 = Offset(cx + b.x * radius, cy + b.y * radius);
        final mid = (p1 + p2) / 2;
        final outward = mid - Offset(cx, cy);
        final ctrl = mid + outward * 0.18;

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SphereConnectionsPainter old) =>
      old.points != points ||
      old.radius != radius ||
      old.cx != cx ||
      old.cy != cy ||
      old.color != color;
}

List<double> _fibonacciPoint(int index, int count) {
  final offset = 2.0 / count;
  final increment = math.pi * (3.0 - math.sqrt(5.0));
  final y = ((index * offset) - 1.0) + (offset / 2.0);
  final radius = math.sqrt(math.max(0.0, 1.0 - y * y));
  final phi = index * increment;
  final x = math.cos(phi) * radius;
  final z = math.sin(phi) * radius;
  return [x, y, z];
}

List<double> _rotateXY(List<double> point, double rx, double ry) {
  final cosX = math.cos(rx);
  final sinX = math.sin(rx);
  final y1 = point[1] * cosX - point[2] * sinX;
  final z1 = point[1] * sinX + point[2] * cosX;

  final cosY = math.cos(ry);
  final sinY = math.sin(ry);
  final x2 = point[0] * cosY + z1 * sinY;
  final z2 = -point[0] * sinY + z1 * cosY;
  return [x2, y1, z2];
}

class _ProjectedChip {
  const _ProjectedChip({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
  });

  final int index;
  final double x;
  final double y;
  final double z;
}

class _SphereChip extends StatelessWidget {
  static const _kImageChipSize = 84.0;
  static const _kImageChipOuterPadding = 10.0;

  const _SphereChip({
    required this.data,
    required this.z,
    required this.perspective,
    required this.isCentered,
    required this.accentColor,
    required this.textColor,
    required this.onTap,
  });

  final _SphereChipData data;
  final double z;
  final double perspective;
  final bool isCentered;
  final Color accentColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final depth = (z + 1) / 2;
    final baseScale = 0.7 + depth * 0.45;
    final centerBoost = isCentered ? 1.25 : 1.0;
    final scale = baseScale * centerBoost;

    final alpha = (0.3 + depth * 0.7).clamp(0.0, 1.0);
    final color = Color.lerp(textColor, accentColor, depth)!.withValues(
      alpha: alpha,
    );
    final bgAlpha = (depth * (isCentered ? 0.22 : 0.12)).clamp(0.0, 0.3);

    const baseFontSize = 18.0;
    final style = TextStyle(
      fontSize: baseFontSize,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.3,
    );

    final decoration = BoxDecoration(
      color: accentColor.withValues(alpha: bgAlpha),
      borderRadius: BorderRadius.circular(20),
      border: isCentered
          ? Border.all(color: accentColor.withValues(alpha: 0.7), width: 1.2)
          : null,
      boxShadow: isCentered
          ? [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ]
          : null,
    );

    Widget chip;
    if (data.imageUrl != null) {
      chip = AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(_kImageChipOuterPadding),
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: _kImageChipSize,
            height: _kImageChipSize,
            child: CommonNetImage(url: data.imageUrl!, fit: BoxFit.cover),
          ),
        ),
      );
    } else {
      chip = AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isCentered ? 18 : 14,
          vertical: isCentered ? 10 : 8,
        ),
        decoration: decoration,
        child: Text(data.label, style: style),
      );
    }

    chip = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: chip,
      ),
    );

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, perspective)
        ..scale(scale),
      child: chip,
    );
  }
}

class _SelectedFieldPane extends StatelessWidget {
  const _SelectedFieldPane({
    super.key,
    required this.slot,
    required this.color,
    required this.accentColor,
    required this.textColor,
    required this.surfaceColor,
    required this.labelStyle,
    required this.typographyDeckId,
    required this.typographyIsFront,
    required this.onClose,
  });

  final CardSlot slot;
  final Color color;
  final Color accentColor;
  final Color textColor;
  final Color surfaceColor;
  final TextStyle? labelStyle;
  final String? typographyDeckId;
  final bool typographyIsFront;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final headerStyle =
        labelStyle?.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(color: accentColor, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(Icons.arrow_back_ios_new, color: accentColor),
                  onPressed: onClose,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    slot.field,
                    style: headerStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: FactContent(
            items: slot.items,
            color: color,
            typographyDeckId: typographyDeckId,
            typographyIsFront: typographyIsFront,
          ),
        ),
      ],
    );
  }
}