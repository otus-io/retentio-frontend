import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

/// Applies a ruby wrap to [controller] using [reading].
///
/// Prefer [start]/[end] captured when the menu opened — hiding the toolbar
/// can collapse the live selection before the reading dialog returns.
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

/// Prompts for a reading for [baseText]. Returns trimmed reading, or null if cancelled/blank.
Future<String?> showWikiRubyReadingDialog(
  BuildContext context, {
  required String baseText,
  required String readingHint,
}) {
  final loc = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => _WikiRubyReadingDialog(
      baseText: baseText,
      readingHint: readingHint,
      loc: loc,
    ),
  );
}

class _WikiRubyReadingDialog extends StatefulWidget {
  const _WikiRubyReadingDialog({
    required this.baseText,
    required this.readingHint,
    required this.loc,
  });

  final String baseText;
  final String readingHint;
  final AppLocalizations loc;

  @override
  State<_WikiRubyReadingDialog> createState() => _WikiRubyReadingDialogState();
}

class _WikiRubyReadingDialogState extends State<_WikiRubyReadingDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    Navigator.of(context).pop(trimmed.isEmpty ? null : trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.loc.factRubyReadingDialogTitle(widget.baseText)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.readingHint),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.loc.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(widget.loc.factRubyApply)),
      ],
    );
  }
}

/// Adds a Ruby button to the selection toolbar when there is a non-empty selection.
Widget wikiRubySelectionToolbar({
  required BuildContext context,
  required EditableTextState editableTextState,
  required AppLocalizations loc,
  required String readingHint,
  required Future<void> Function(
    String reading, {
    required int start,
    required int end,
  })
  onReadingChosen,
}) {
  final defaultButtonItems = editableTextState.contextMenuButtonItems;
  final selection = editableTextState.textEditingValue.selection;
  final text = editableTextState.textEditingValue.text;

  void scheduleRubyReading({
    required String base,
    required int start,
    required int end,
  }) {
    final hostContext = editableTextState.context;
    ContextMenuController.removeAny();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!hostContext.mounted) return;
      final reading = await showWikiRubyReadingDialog(
        hostContext,
        baseText: base,
        readingHint: readingHint,
      );
      if (reading == null || !hostContext.mounted) return;
      await onReadingChosen(reading, start: start, end: end);
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
        scheduleRubyReading(base: base, start: start, end: end);
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
