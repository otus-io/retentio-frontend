import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

/// Applies a ruby wrap to [controller] using [reading] (may be empty for inline add).
///
/// Prefer [start]/[end] captured when the menu opened — hiding the toolbar
/// can collapse the live selection before the wrap runs.
bool wikiRubyApplyWrapToController(
  TextEditingController controller,
  String reading, {
  int? start,
  int? end,
}) {
  final selection = controller.selection;
  final rangeStart = start ?? selection.start;
  final rangeEnd = end ?? selection.end;
  final next = WikiRubyMarkup.wrapSelection(
    text: controller.text,
    start: rangeStart,
    end: rangeEnd,
    reading: reading,
  );
  if (next == null) return false;
  final kanji = controller.text.substring(rangeStart, rangeEnd);
  final marker = '[[$kanji|${reading.trim()}]]';
  controller.value = TextEditingValue(
    text: next,
    selection: TextSelection.collapsed(
      offset: (rangeStart + marker.length).clamp(0, next.length),
    ),
  );
  return true;
}

/// Adds a Ruby button to the selection toolbar when there is a non-empty selection.
///
/// Activating Ruby wraps with an empty reading so the card editor can focus the
/// inline reading field (no dialog).
Widget wikiRubySelectionToolbar({
  required BuildContext context,
  required EditableTextState editableTextState,
  required AppLocalizations loc,
  required Future<void> Function({required int start, required int end})
  onRubyWrap,
}) {
  final defaultButtonItems = editableTextState.contextMenuButtonItems;
  final selection = editableTextState.textEditingValue.selection;
  final text = editableTextState.textEditingValue.text;

  void scheduleRubyWrap({required int start, required int end}) {
    ContextMenuController.removeAny();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await onRubyWrap(start: start, end: end);
    });
  }

  if (selection.isValid && !selection.isCollapsed) {
    final base = text.substring(selection.start, selection.end);
    if (base.isNotEmpty &&
        !base.contains('[') &&
        !base.contains(']') &&
        !base.contains('|')) {
      final start = selection.start;
      final end = selection.end;
      void onRubyActivate() {
        scheduleRubyWrap(start: start, end: end);
      }

      final rubyButton = _WikiRubyToolbarButton(
        label: loc.factRubyMenuLabel,
        onActivate: onRubyActivate,
      );
      final defaultButtons = AdaptiveTextSelectionToolbar.getAdaptiveButtons(
        context,
        defaultButtonItems,
      );
      return AdaptiveTextSelectionToolbar(
        anchors: editableTextState.contextMenuAnchors,
        children: [rubyButton, ...defaultButtons],
      );
    }
  }
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: defaultButtonItems,
  );
}

/// Ruby menu row: [onPointerDown] runs before selection can collapse and rebuild
/// the toolbar without the Ruby action (macOS/iOS selection menu race).
class _WikiRubyToolbarButton extends StatelessWidget {
  const _WikiRubyToolbarButton({required this.label, required this.onActivate});

  final String label;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final visual = AdaptiveTextSelectionToolbar.getAdaptiveButtons(context, [
      ContextMenuButtonItem(label: label, onPressed: onActivate),
    ]).first;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => onActivate(),
      child: AbsorbPointer(child: visual),
    );
  }
}
