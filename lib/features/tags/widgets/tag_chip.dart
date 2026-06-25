import 'package:flutter/material.dart';
import 'package:retentio/models/tag.dart';

/// A compact chip displaying a [Tag] name.
///
/// When [onRemove] is provided, an × icon is shown on the right; tapping it
/// calls [onRemove]. When [onTap] is provided, the whole chip is tappable.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tag,
    this.onRemove,
    this.onTap,
    this.compact = false,
  });

  final Tag tag;

  /// Called when the × icon is tapped. If null, the × icon is not shown.
  final VoidCallback? onRemove;

  /// Called when the chip body is tapped (e.g. to toggle selection).
  final VoidCallback? onTap;

  /// When true, uses a tighter padding (for dense lists).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final chip = Material(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
              : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: scheme.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return chip;
  }
}

/// A horizontal scrollable row of [TagChip]s.
///
/// Commonly used in deck-create / fact-composer to show selected tags.
class TagChipRow extends StatelessWidget {
  const TagChipRow({
    super.key,
    required this.tags,
    this.onRemove,
    this.emptyWidget,
  });

  final List<Tag> tags;

  /// If provided, shows × on each chip and calls this with the tag id.
  final void Function(String tagId)? onRemove;

  /// Widget to show when [tags] is empty. Defaults to nothing.
  final Widget? emptyWidget;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return emptyWidget ?? const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: TagChip(
                  tag: t,
                  onRemove: onRemove != null ? () => onRemove!(t.id) : null,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
