import 'package:flutter/material.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/deck/card_widgets/card_wiki_ruby_layout.dart';
import 'package:retentio/utils/wiki_ruby_markup.dart';

const _kRubyTapPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 8);
const _kRubyTapMinWidth = 36.0;
const _kRubyTapMinHeight = 44.0;
const _kRubyTapRadius = 6.0;
const _kRubyIdleFillAlpha = 0.07;
const _kRubyReadingUnderlineAlpha = 0.45;

class _RubyEditSlot {
  _RubyEditSlot.plain({required this.controller}) : kanji = null, focus = null;

  _RubyEditSlot.ruby({
    required this.kanji,
    required this.controller,
    required this.focus,
  });

  final String? kanji;
  final TextEditingController controller;
  final FocusNode? focus;
  VoidCallback? focusListener;
}

/// Card-style display with tap-to-edit readings. Syncs `[[base|reading]]` into [storage].
class WikiRubyContentEditor extends StatefulWidget {
  const WikiRubyContentEditor({
    super.key,
    required this.storage,
    required this.baseStyle,
    required this.readingHint,
    this.contentPadding = EdgeInsets.zero,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController storage;
  final TextStyle baseStyle;
  final String readingHint;
  final EdgeInsets contentPadding;
  final TextAlign textAlign;

  @override
  State<WikiRubyContentEditor> createState() => _WikiRubyContentEditorState();
}

class _WikiRubyContentEditorState extends State<WikiRubyContentEditor> {
  late List<_RubyEditSlot> _slots;
  bool _syncingStorage = false;
  String _trackedStorage = '';
  int? _editingRubyIndex;

  @override
  void initState() {
    super.initState();
    _trackedStorage = widget.storage.text;
    _slots = _slotsFromStorage(_trackedStorage);
    widget.storage.addListener(_onStorageExternalChange);
    for (final slot in _slots) {
      slot.controller.addListener(_syncToStorage);
      _attachRubyFocus(slot);
    }
  }

  @override
  void dispose() {
    widget.storage.removeListener(_onStorageExternalChange);
    for (final slot in _slots) {
      slot.controller.removeListener(_syncToStorage);
      _detachRubyFocus(slot);
      slot.controller.dispose();
      slot.focus?.dispose();
    }
    super.dispose();
  }

  void _attachRubyFocus(_RubyEditSlot slot) {
    final focus = slot.focus;
    if (focus == null) return;
    void listener() {
      if (focus.hasFocus) return;
      if (!mounted) return;
      final index = _slots.indexOf(slot);
      if (index >= 0 && _editingRubyIndex == index) {
        setState(() => _editingRubyIndex = null);
      }
    }

    slot.focusListener = listener;
    focus.addListener(listener);
  }

  void _detachRubyFocus(_RubyEditSlot slot) {
    final focus = slot.focus;
    final listener = slot.focusListener;
    if (focus != null && listener != null) {
      focus.removeListener(listener);
    }
    slot.focusListener = null;
  }

  void _onStorageExternalChange() {
    if (_syncingStorage || widget.storage.text == _trackedStorage) return;
    _replaceSlots(_slotsFromStorage(widget.storage.text));
  }

  void _replaceSlots(List<_RubyEditSlot> next) {
    for (final slot in _slots) {
      slot.controller.removeListener(_syncToStorage);
      _detachRubyFocus(slot);
      slot.controller.dispose();
      slot.focus?.dispose();
    }
    _slots = next;
    _trackedStorage = widget.storage.text;
    _editingRubyIndex = null;
    for (final slot in _slots) {
      slot.controller.addListener(_syncToStorage);
      _attachRubyFocus(slot);
    }
    setState(() {});
  }

  List<_RubyEditSlot> _slotsFromStorage(String raw) {
    return [
      for (final piece in WikiRubyMarkup.decompose(raw))
        if (piece is WikiRubyComposePlain)
          _RubyEditSlot.plain(
            controller: TextEditingController(text: piece.text),
          )
        else if (piece is WikiRubyComposeRuby)
          _RubyEditSlot.ruby(
            kanji: piece.kanji,
            controller: TextEditingController(text: piece.reading),
            focus: FocusNode(),
          ),
    ];
  }

  List<WikiRubyComposePiece> _composePieces() {
    return [
      for (final slot in _slots)
        if (slot.kanji == null)
          WikiRubyComposePlain(slot.controller.text)
        else
          WikiRubyComposeRuby(
            kanji: slot.kanji!,
            reading: slot.controller.text,
          ),
    ];
  }

  void _syncToStorage() {
    final next = WikiRubyMarkup.compose(_composePieces());
    if (next == _trackedStorage) return;
    _syncingStorage = true;
    _trackedStorage = next;
    widget.storage.value = widget.storage.value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
      composing: TextRange.empty,
    );
    _syncingStorage = false;
  }

  void _startEditingRuby(int index) {
    setState(() => _editingRubyIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _slots[index].focus?.requestFocus();
    });
  }

  void _focusNextRuby(int fromIndex) {
    for (var i = fromIndex + 1; i < _slots.length; i++) {
      if (_slots[i].kanji != null) {
        _startEditingRuby(i);
        return;
      }
    }
    setState(() => _editingRubyIndex = null);
    _slots[fromIndex].focus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final rubyStyle = wikiRubyReadingStyle(widget.baseStyle);
    final scheme = Theme.of(context).colorScheme;
    final wrapAlignment = switch (widget.textAlign) {
      TextAlign.start || TextAlign.left => WrapAlignment.start,
      TextAlign.end || TextAlign.right => WrapAlignment.end,
      _ => WrapAlignment.center,
    };

    return Padding(
      padding: widget.contentPadding,
      child: FocusTraversalGroup(
        child: Wrap(
          alignment: wrapAlignment,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 0,
          runSpacing: 6,
          children: [
            for (var i = 0; i < _slots.length; i++)
              _buildSlot(context, i, rubyStyle, scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(
    BuildContext context,
    int index,
    TextStyle rubyStyle,
    ColorScheme scheme,
  ) {
    final slot = _slots[index];
    if (slot.kanji == null) {
      return Text(slot.controller.text, style: widget.baseStyle);
    }

    final kanji = slot.kanji!;
    final reading = slot.controller.text;
    final editing = _editingRubyIndex == index;
    final isLastRuby = !_hasRubyAfter(index);
    final textInputAction = isLastRuby
        ? TextInputAction.done
        : TextInputAction.next;

    if (!editing) {
      return _rubyTapTarget(
        scheme: scheme,
        onTap: () => _startEditingRuby(index),
        child: wikiRubyCellWidget(
          kanji: kanji,
          reading: reading,
          baseStyle: widget.baseStyle.copyWith(color: scheme.onSurface),
          rubyStyle: rubyStyle.copyWith(
            color: scheme.onSurface,
            decoration: TextDecoration.underline,
            decorationColor: scheme.primary.withValues(
              alpha: _kRubyReadingUnderlineAlpha,
            ),
            decorationStyle: TextDecorationStyle.dotted,
          ),
        ),
      );
    }

    return FocusTraversalOrder(
      order: NumericFocusOrder(index.toDouble()),
      child: _rubyTapTarget(
        scheme: scheme,
        highlighted: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IntrinsicWidth(
                child: TextField(
                  controller: slot.controller,
                  focusNode: slot.focus,
                  style: rubyStyle.copyWith(color: scheme.primary),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.readingHint,
                    hintStyle: rubyStyle.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: scheme.primary, width: 2),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  textInputAction: textInputAction,
                  onSubmitted: (_) => _focusNextRuby(index),
                ),
              ),
              Text(
                kanji,
                style: widget.baseStyle.copyWith(color: scheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rubyTapTarget({
    required ColorScheme scheme,
    required Widget child,
    VoidCallback? onTap,
    bool highlighted = false,
  }) {
    final fill = highlighted
        ? scheme.primary.withValues(alpha: _kRubyIdleFillAlpha * 2)
        : scheme.primary.withValues(alpha: _kRubyIdleFillAlpha);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(_kRubyTapRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kRubyTapRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _kRubyTapMinWidth,
            minHeight: _kRubyTapMinHeight,
          ),
          child: Padding(padding: _kRubyTapPadding, child: child),
        ),
      ),
    );
  }

  bool _hasRubyAfter(int index) {
    for (var i = index + 1; i < _slots.length; i++) {
      if (_slots[i].kanji != null) return true;
    }
    return false;
  }
}

/// Whether [text] should use the ruby reading editor instead of a plain field.
bool wikiRubyContentUsesReadingEditor(String text) =>
    WikiRubyMarkup.looksLikeMarkup(text);

/// Localized hints for [WikiRubyContentEditor].
({String reading, String plain}) wikiRubyContentEditorHints(
  AppLocalizations loc,
) => (reading: loc.factRubyReadingHint, plain: loc.addFactContentHint);
